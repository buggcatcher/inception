
## Risorse Ufficiali per Inception

### 📜 Il Progetto
*   **[Subject Ufficiale di Inception (42)](https://cdn.intra.42.fr/pdf/pdf/202754/en.subject.pdf)**: La "bibbia" del progetto. Leggilo più e più volte, ogni dettaglio è importante. Contiene tutti i requisiti fondamentali, dalla struttura delle directory ai divieti sull'uso di `latest` e `--link`.

---

### 🐳 Docker: Fondamenti e Best Practices

*   **[Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)**: La guida definitiva per scrivere un Dockerfile. Copre ogni singola istruzione (`FROM`, `RUN`, `COPY`, `CMD`, `ENTRYPOINT`, `EXPOSE`, `VOLUME`, `USER`, `WORKDIR`). È un must per creare immagini personalizzate da zero.
*   **[Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)**: Il "galateo" di Docker. Spiega perché ottimizzare i layer per la cache, usare un `.dockerignore`, creare container "effimeri" e, cosa fondamentale, lanciare un solo processo per container in primo piano (foreground) per evitare hack come `tail -f` e rispettare il PID 1.
*   **[Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)**: Il manuale per orchestrare i servizi. Qui trovi come definire l'infrastruttura: `services`, `volumes` (named volumes), `networks`, `depends_on`, `restart: always` (fondamentale per i crash) e come usare le variabili d'ambiente.
*   **[Docker Volumes (Named Volumes)](https://docs.docker.com/storage/volumes/)**: Spiega come creare e gestire named volumes, fondamentali per la persistenza dei dati del database e dei file di WordPress. La sezione sui driver (`local` con `driver_opts`) è essenziale per mapparli fisicamente su `/home/login/data/`.
*   **[Docker Compose Environment Variables / `.env` file](https://docs.docker.com/compose/environment-variables/)**: Documentazione su come passare variabili d'ambiente a Docker Compose usando un file `.env` e l'istruzione `env_file` nel docker-compose.yml. Le password e le credenziali vanno qui, non nel codice o nei Dockerfile.
*   **[Docker Compose Secrets](https://docs.docker.com/compose/use-secrets/)**: Il metodo "fortemente raccomandato" dal subject per gestire informazioni sensibili. Invece di variabili d'ambiente, i segreti vengono montati come file read-only. Molto più sicuro.

---


### 🐧 Debian Linux (Base OS Consigliata)

*   **[APT Package Manager (`apt`)](https://wiki.debian.org/Teams/Apt)**: La guida al package manager di Debian. Usare `apt-get update` seguito da `apt-get install -y` nei Dockerfile è fondamentale per installare pacchetti in modo pulito. Ricorda di eseguire `apt-get clean` e rimuovere `/var/lib/apt/lists/*` per mantenere l'immagine leggera e senza cache inutili.
*   **[Debian Releases](https://www.debian.org/releases/)**: Per scegliere la **penultima versione stabile** richiesta dal progetto. Ad esempio, se l'ultima stabile è la 12 (bookworm), userai la 11 (bullseye).

---

### 🔧 Servizi Specifici

*   **[NGINX Documentation](https://nginx.org/en/docs/)**: La configurazione del reverse proxy. Sarà l'unico punto d'accesso alla tua infrastruttura sulla `porta 443`, quindi dovrai configurarlo per parlare con PHP-FPM (via `fastcgi_pass`) e per servire i file statici di WordPress.
*   **[OpenSSL `req` Command](https://www.openssl.org/docs/man3.0/man1/openssl-req.html)**: Per generare i certificati TLS (solo v1.2/v1.3) self-signed direttamente nel Dockerfile durante la build, rispettando il requisito di non distribuirli nel repository.
*   **[PHP-FPM (FastCGI Process Manager)](https://www.php.net/manual/en/install.fpm.php)**: Configurazione di PHP-FPM e spiegazione dell'uso del flag `-F` per eseguirlo in foreground, assicurando che il container non si spenga.
*   **[WP-CLI Official Documentation](https://make.wordpress.org/cli/handbook/)**: Lo strumento ufficiale a riga di comando per WordPress [9†L4-L9], ti permetterà di installare e configurare WordPress direttamente da riga di comando tramite uno script, evitando il wizard web e automatizzando la creazione di utenti (attenzione al vincolo sul nome admin). Verrà utilizzato insieme a `curl` nel tuo script entrypoint per scaricare e installare l'ultima versione di WordPress e configurare il suo `wp-config.php`.
*   **[MariaDB Server Documentation](https://mariadb.com/kb/en/documentation/)**: Configurazione del database. Dovrai configurare i file (`50-server.cnf`) per permettere la connessione da WordPress e avviare il `mysqld` in foreground. Dovrai anche inizializzare il database utente e il database di WordPress al primo avvio usando un init script. Un esempio di inizializzazione del database potrebbe essere simile a questo:
    ```sql
    CREATE DATABASE IF NOT EXISTS wordpress;
    CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY 'password';
    GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
    FLUSH PRIVILEGES;
    ```
*   **[How to Use the Command 'apt' (with Examples)](https://www.cyberciti.biz/faq/debian-ubuntu-linux-apt-get-command-examples/)**: Un riferimento pratico e veloce per i comandi `apt` più comuni, come `apt-get install`, `apt-get remove`, `apt-get update`, `apt-cache search`, `apt-cache show` e altri utili durante la scrittura del Dockerfile.

---

### ⚙️ Processi e Automazione

*   **[GNU Make Manual](https://www.gnu.org/software/make/manual/)**: Per scrivere un Makefile solido con i target `all`, `up`, `down`, `clean`, `fclean`, `re`. Dovrà creare le directory dei volumi (es. `/home/login/data/wordpress`, `/home/login/data/mariadb`) e lanciare il `docker-compose up --build -d`.
*   **[Docker and the PID 1 Zombie Reaping Problem](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)**: (Non ufficiale ma fondamentale). Capire perché i container non sono VM e perché servono processi in foreground. Il processo con PID 1 deve gestire i segnali (`SIGTERM`) e i figli zombie. Spiega perché uno script di entrypoint deve terminare con `exec` per rimpiazzare la shell con il processo principale (es. `exec nginx -g 'daemon off;'`).
*   **[Official Docker Build Secrets Guide](https://www.hostinger.com/tutorials/docker-build-secrets)**: Una guida che spiega le best practice per non usare `ENV` o `ARG` per le password nei Dockerfile. Include la gestione dei segreti di build, utile se devi autenticarti per scaricare pacchetti durante la fase di `docker build` ed evitare che le credenziali rimangano nell'immagine finale.

---

## Guide online

Ecco un buon punto di partenza:

- [Inception Guide – Part I (Medium)](https://medium.com/@ssterdev/inception-guide-42-project-part-i-7e3af15eb671)
- [Inception Guide – Part II (Medium)](https://medium.com/@ssterdev/inception-42-project-part-ii-19a06962cf3b)

Queste guide contengono **spunti utili** (es. l'uso di `wp-cli`, la struttura delle cartelle `requirements/`), ma **presentano diverse incongruenze** rispetto al subject ufficiale di 42. Seguirle senza correzioni può portare a una valutazione negativa.

Di seguito una tabella riassuntiva dei principali problemi riscontrati in quelle guide, con le relative correzioni richieste dal progetto.

| 📌 Problema nella guida Medium | Cosa dice/suggerisce la guida | ✅ Cosa richiede il subject ufficiale |
|-------------------------------|-------------------------------|----------------------------------------|
| **TLS/HTTPS assente** | “I will not cover TLS encryption in this guide for now” – nessuna configurazione di HTTPS. | **Obbligatorio**: NGINX deve ascoltare solo sulla **porta 443** con **TLSv1.2 o TLSv1.3**. |
| **Bind mount per i file di WordPress** | Usa `./web:/var/www/html` (bind mount). | **Vietato** per i volumi persistenti. Vanno usati **named volumes** (es. `wordpress_files`). |
| **Percorso dei volumi non conforme** | Non specifica il percorso `/home/login/data`. | I named volumes devono essere mappati su `/home/login/data/wordpress` e `/home/login/data/mariadb` tramite `driver_opts`. |
| **Password in chiaro nel docker-compose.yml** | Scrive `MYSQL_PASSWORD=password` direttamente nel file YAML. | **Vietato**. Le credenziali vanno nel file `.env` (ignorato da git) o in Docker secrets. |
| **Nessun volume named per il database** | Non definisce un volume esplicito per MariaDB. | **Obbligatorio**: volume named separato per i dati del database (`mariadb_data`). |
| **Assenza di `restart` policy** | Non specifica alcuna politica di riavvio. | Richiesto: *“Your containers have to restart in case of a crash”* → `restart: unless-stopped` o `always`. |
| **Uso di `docker cp` per estrarre configurazioni** | Copia file da container in esecuzione per modificarli. | Non vietato, ma **pessima pratica**. I file di configurazione vanno creati manualmente nella cartella `conf/` e copiati nel Dockerfile. |
| **Nessun file `.env`** | Tutte le variabili sono scritte inline. | **Obbligatorio** usare un file `.env` separato per ambiente e segreti. |
| **Mancata gestione del PID 1 e foreground** | Usa `mysqld_safe` (che demonizza) e non educa su `exec`. | **Vietato ogni hack** (`tail -f`, `sleep infinity`, demonizzare). Tutti i servizi devono partire **in foreground** (es. `nginx -g 'daemon off;'`, `php-fpm -F`, `mysqld` senza `--daemonize`). |
| **Nessuna verifica di readiness tra servizi** | Affida tutto a `depends_on`, che non garantisce che MariaDB sia pronto. | È necessario implementare un **wait loop** nello script di entrypoint di WordPress (es. `while ! nc -z mariadb 3306; do sleep 1; done`). |


---

## keywords fondamentali
Dockerfile:

    FROM, RUN, COPY, WORKDIR, EXPOSE, CMD / ENTRYPOINT con forma exec.

    USER per non usare root.

    ARG / ENV (ma mai per password).

Docker Compose:

    build, image, container_name, ports, volumes (named), networks, depends_on, restart, env_file, environment.

    driver_opts per mappare i volumi su /home/login/data.

## altre keywords

Di seguito quattro tabelle concise e leggibili per riferirsi rapidamente alle istruzioni/chiavi e alle buone pratiche da usare nei Dockerfile e in `docker-compose.yml` per il progetto Inception.

**Dockerfile — Istruzioni principali**

| Keyword | Cosa fa | Esempio (Inception) |
|---|---|---|
| FROM | Definisce l'immagine base (prima istruzione). | `FROM debian:11-slim` |
| RUN | Esegue comandi durante la build, crea layer. | `RUN apt-get update && apt-get install -y nginx` |
| COPY | Copia file dalla build context all'immagine. | `COPY conf/nginx.conf /etc/nginx/` |
| WORKDIR | Imposta la working directory per i comandi successivi. | `WORKDIR /var/www/html` |
| EXPOSE | Documenta la porta su cui il servizio ascolta. | `EXPOSE 443` |
| ENV / ARG | ENV persiste nel container, ARG solo in build. Evitare per password. | `ARG DEBIAN_FRONTEND=noninteractive` |
| USER | Cambia l'utente per esecuzione (non usare root). | `USER www-data` |
| CMD / ENTRYPOINT | CMD è il comando di default; ENTRYPOINT per script d'init. Usare forma exec e avviare processi in foreground. | `ENTRYPOINT ["/usr/local/bin/wp-setup.sh"]` |
| VOLUME | Dichiara punti di mount per dati persistenti. | `VOLUME /var/lib/mysql` |
| HEALTHCHECK | Controllo di salute del container. | `HEALTHCHECK CMD curl -f https://localhost/ || exit 1` |
| LABEL | Metadati dell'immagine. | `LABEL maintainer="login@42.fr"` |

**Docker Compose — Chiavi principali**

| Keyword | Cosa fa | Esempio (Inception) |
|---|---|---|
| build / context / dockerfile | Definisce il contesto di build e il Dockerfile. | `build: { context: ./nginx, dockerfile: Dockerfile }` |
| image | Nome e tag dell'immagine da usare o generare. | `image: nginx:inception` |
| container_name | Assegna un nome leggibile al container. | `container_name: inception_nginx` |
| ports | Espone porte host:container. | `- "443:443"` |
| volumes | Monta volumi (usare named volumes per persistenza). | `- wordpress_files:/var/www/html` |
| networks | Collega servizi a reti specifiche. | `networks: - inception` |
| environment / env_file | Variabili d'ambiente; usare `.env` (ignorato da git). | `env_file: - .env` |
| depends_on / restart | Dipendenze d'avvio; restart policy richiesta. | `depends_on: - mariadb\nrestart: unless-stopped` |
| command / entrypoint | Sovrascrive CMD/ENTRYPOINT del Dockerfile. | `command: ["nginx","-g","daemon off;"]` |
| healthcheck | Definisce test di salute per il servizio. | `healthcheck: { test: ["CMD","curl","-f","http://localhost"], interval: 30s }` |
| logging | Configura driver e limiti dei log. | `logging: { driver: "json-file", options: { max-size: "10m" } }` |

**Volumi Named & Reti**

| Oggetto | Cosa fa | Esempio / Nota |
|---|---|---|
| volumes (driver) | Definisce named volumes e driver (default `local`). | `volumes:\n  wordpress_files:` |
| driver_opts | Mappa il volume su percorso host richiesto da Inception. | `driver_opts: { type: none, device: /home/login/data/wordpress, o: bind }` |
| external | Indica che il volume è gestito esternamente. | `external: false` |
| networks (driver / ipam) | Configura tipo di rete e subnet opzionale. | `driver: bridge` |
| secrets / configs | Segreti montati come file read-only; configs per file non sensibili. | `secrets: { db_password: { file: ./secrets/db_password.txt } }` |

**Buone pratiche e note rapide**

| Argomento | Perché importante | Suggerimento rapido |
|---|---|---|
| Processi in foreground | Evita che i container si arrestino; rispetta PID 1. | Usare `exec` e avviare i servizi senza demonizzare (es. `nginx -g 'daemon off;'`). |
| Named volumes & percorso | Persistenza e conformità con il subject. | Mappare su `/home/login/data/...` con `driver_opts`. |
| Segreti vs .env | Evita credenziali in chiaro nel repo o in Dockerfile. | Usare Docker secrets o `.env` ignorato da git; non usare `ENV` per password. |
| Evitare `latest` | `latest` causa incoerenze e valutazione negativa. | Usare tag espliciti e la penultima release richiesta. |
| Readiness tra servizi | `depends_on` non garantisce readiness (solo avvio). | Implementare wait loops nello entrypoint (es. `while ! nc -z mariadb 3306; do sleep 1; done`). |
| PID 1 e reaping | PID 1 deve gestire segnali e figli zombie. | Terminare entrypoint con `exec` per rimpiazzare la shell. |





*This is AI-generated, for reference only.*
