attraverso comandi come `docker build` e `docker compose` dico a docker cosa usare e dove trovarlo. I seguenti file servono proprio a questo. Il demone `dockerd` gira sulla macchina e io gli posso invia re comanti attraverso il terminale i cui percorsi sono relativi al mio filesystem.
guarda il subject per i certificati (tls).
non ci sono cartelle con nomi speciali o che devo usare per forza ma posso usare /src, /tool e /conf per aiutarmi a organizzare i file.


## File / Directory  Scopo

| File / Directory | Scopo |
|---|---|
| `Makefile` | Punto di ingresso. Crea le cartelle dei volumi sull’host (`/home/login/data/...`), lancia `docker compose up --build -d`, ferma e pulisce. |
| `.env` | Variabili d’ambiente (nomi utente, password, dominio). Non committato (`.gitignore`). |
| `docker-compose.yml` | Definisce i servizi, la rete, i volumi named (con driver local mappato su `/home/login/data`), le variabili d’ambiente, le dipendenze (`depends_on`), la politica di restart. |
| `Dockerfile` | Costruisce l’immagine per quel servizio partendo da Alpine. Installa i pacchetti, copia configurazioni e script, imposta il comando di avvio (o entrypoint). |
| `*.conf` | File di configurazione specifici per nginx, php-fpm, mariadb. Vengono copiati nel container durante il build. |
| `*.sh` | Script di entrypoint o di utilità (es. attesa del database, generazione certificati, installazione WordPress). Devono terminare con `exec` per sostituire la shell. |
| `.gitignore` | Dice a Git quali file/cartelle NON tracciare nel repository (non versionarli). |
| `.dockerignore` | Dice a Docker quali file/cartelle escludere dal contesto di build (quando si fa `docker build`), così non vengono inviati al Docker daemon. Usa la prima regola che matcha quindi attento all'ordine. |
   
---
   
Esiste anche il `tmpfs mount`: i dati sono scritti in RAM e non persistono.
Non c’è condivisione con l’host.
Utile per dati temporanei sensibili (password, sessioni).

`named volume` e `bin mount` sono due modi per gestire i file persistenti.
il primo gestito da docker e sta in /var/lib/docker/volumes/ 
il secondo sta su un percorso assoluto del container dell'host 
il primo mi sembra migliore in quanto supporta driver come NFS, S3, block storage, cifratura, etc.
inoltre é portabile nel senso che posso usare lo stesso named volume su qualsiasi host, mentre nel primo dipende dalla struttura delle directory del host. quindi per motivi di sicurezza, isolamento e portabilitá sceglieró il secondo ma a quanto pare non é l'ideale per tutto, ecco cosa diche deepseek:

| Cosa | Bind mount | Named volume | Usato in Inception |
|---|---|---|---|
| File di configurazione (es. `nginx.conf`, `wp-config.php`) | ✅ Ideale durante lo sviluppo (modifichi sull’host e vedi subito il cambiamento) | ❌ Non pratico perché devi entrare nel volume per modificare | Nei requisiti, di solito si copia con `COPY` nel Dockerfile (perché la configurazione è fissa). Ma per flessibilità puoi usare bind mount in fase di test. |
| Dati persistenti di WordPress (upload, plugin) | ⚠️ Si può, ma meno portabile (path assoluti) | ✅ Consigliato – volume nominato `wp_data` | Obbligatorio – il progetto richiede un volume per i file di WP |
| Dati del database | ⚠️ Sconsigliato (permessi, portabilità) | ✅ Obbligatorio – volume `db_data` | Obbligatorio |
| Log o file temporanei | Puoi usare bind mount per debug | Meno comune | Non richiesto |


   
---
   
## File di configurazione per ogni servizio:

Nel Dockerfile copi il file .conf nell'immagine:
```dockerfile
COPY nginx.conf /etc/nginx/nginx.conf
```
Così ogni container parte con quella configurazione.

Per i segreti come password e token é bene usare variabili d'ambiente o secrets di Docker Swarm/K8s
é buona pratica usare la modalità read-only (:ro) quando monti file .conf per sicurezza.
un'altra buona pratica é tenere i file .conf sotto versionamento con git separatamente dalle immagini.
   
---
   
`entrypoint.sh` serve tipicamente a:

    Preparare l’ambiente
        Creare directory necessarie (es. /var/log/app, /data/tmp)
        Impostare permessi (es. chown -R app:app /data)
        Sostituire variabili d’ambiente in file di configurazione (es. con envsubst)

    Eseguire operazioni di bootstrap
        Attendere che un servizio dipendente sia pronto (es. wait-for-it db:5432)
        Applicare migrazioni del database (es. python manage.py migrate)
        Popolare cache o directory con dati iniziali

    Avviare il processo principale
        Lanciare il comando finale (es. nginx -g "daemon off;", gunicorn app:app)
        Usare exec per sostituire lo script con il processo, così i segnali (SIGTERM) arrivano direttamente al servizio

    Gestire segnali e shutdown graceful
        Alcuni script avanzati catturano SIGTERM per fermare il servizio pulitamente


# da leggere e aproffondire:
deepseek consiglia:

Nel tuo `docker-compose.yml` userai:
```yaml
volumes:
  wp_data:
  db_data:

services:
  wordpress:
    volumes:
      - wp_data:/var/www/html
  mariadb:
    volumes:
      - db_data:/var/lib/mysql
```

## ⚙️ File .conf in Inception

Ogni servizio avrà i suoi file di configurazione `.conf`:

- **NGINX** → `nginx.conf` o un file in `conf.d/` (es. `wordpress.conf`).  
  Dovrai configurare il `server_name`, `root`, `fastcgi_pass` a WordPress, e abilitare TLS.

- **MariaDB** → `50-server.cnf` o `my.cnf` – puoi personalizzare bind-address, caratteri, etc.

- **PHP-FPM** → `www.conf` o `php.ini` – per impostare `upload_max_filesize`, `memory_limit`, etc.

Di solito in Inception si **copiano** questi file nell’immagine con `COPY`, perché le regole sono fisse.  
Ma per seguire le best practice, puoi anche usarli come **bind mount** durante lo sviluppo per iterare velocemente.

## 🐚 Script di avvio (entrypoint)

Quasi ogni container in Inception avrà bisogno di **uno script** per "far funzionare le cose". Ecco cosa farà tipicamente:

### Per WordPress (PHP-FPM)
- Attendere che MariaDB sia pronto (es. con `wp-cli` o `nc -z`)
- Configurare `wp-config.php` con le variabili d’ambiente (DB_NAME, DB_USER, DB_PASSWORD, DB_HOST)
- Installare WordPress se non già presente (usando `wp core install`)
- Installare temi/plugin (opzionale)
- Infine lanciare `php-fpm8.2 -F`

### Per MariaDB
- Lo script ufficiale `docker-entrypoint.sh` già fa tutto: inizializza il DB se il volume è vuoto, esegue script in `/docker-entrypoint-initdb.d/`.  
  Spesso non serve scriverne uno da zero, ma puoi aggiungere uno script personalizzato che imposta privilegi o crea DB extra.

### Per NGINX
- Di solito non serve script (basta `CMD ["nginx", "-g", "daemon off;"]`).  
  Se vuoi ricaricare la configurazione a caldo o generare certificati SSL all’avvio, puoi usare un entrypoint.

### Esempio di entrypoint per WordPress (semplificato)
```bash
#!/bin/sh
set -e

# Attesa db
while ! nc -z mariadb 3306; do
  echo "Waiting for MariaDB..."
  sleep 2
done

# Configura wp-config.php se non esiste
if [ ! -f /var/www/html/wp-config.php ]; then
  wp config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASSWORD" --dbhost="$DB_HOST" --allow-root
fi

# Installa WP se non già installato
if ! wp core is-installed --allow-root; then
  wp core install --url="$WP_URL" --title="$WP_TITLE" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASS" --admin_email="$WP_ADMIN_EMAIL" --allow-root
fi

exec php-fpm8.2 -F
```

## 🚫 .dockerignore e .gitignore in Inception

Avrai una struttura come:
```
inception/
├── srcs/
│   ├── docker-compose.yml
│   ├── .env
│   ├── requirements/
│   │   ├── nginx/
│   │   │   ├── Dockerfile
│   │   │   ├── conf/nginx.conf
│   │   ├── wordpress/
│   │   │   ├── Dockerfile
│   │   │   ├── conf/wp-config.php
│   │   │   ├── tools/entrypoint.sh
│   │   └── mariadb/
│   │       ├── Dockerfile
│   │       └── conf/my.cnf
├── Makefile
├── .gitignore
├── .dockerignore
```

- **.gitignore** → escludi `.env` (se contiene password), `*.log`, `data/` (se fai backup locali), eventuali volumi locali.
- **.dockerignore** → escludi `.git`, `README.md`, `.env` (ma attento: le tue immagini potrebbero aver bisogno di `.env`? No, le variabili vanno passate via docker-compose o `--env-file`). Escludi anche `Dockerfile` se lo copi dentro? No, ma escludi file non necessari come `Makefile`, `.gitignore`, etc.

## 🧪 Consigli pratici per Inception

1. **Usa named volumes** per wp_data e db_data – è un requisito esplicito del progetto.
2. **Non usare bind mount** per i file del tema/plugin se non in fase di sviluppo personale; il progetto chiede che i file siano **copiati nell’immagine** o persistenti nel volume.
3. **Scrivi entrypoint.sh** per WordPress e per MariaDB (se vuoi inizializzare qualcosa in più).
4. **Mantieni i file .conf** dentro la cartella `requirements/*/conf/` e copiali nel Dockerfile.
5. **Usa variabili d’ambiente** per dati sensibili (DB_PASSWORD, ecc.) e caricale da un file `.env` con docker-compose.
6. **Impara a usare `docker-compose logs -f`** e `docker exec -it` per debug.

Se vuoi, posso aiutarti a scrivere un Dockerfile per uno dei servizi, o a strutturare lo script di entrypoint per WordPress con `wp-cli`. Dimmi pure su quale parte hai più dubbi! 😊

