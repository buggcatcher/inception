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





