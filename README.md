
## Risorse Ufficiali per Inception

### 📜 Il Progetto
*   **[Subject Ufficiale di Inception (42)](https://cdn.intra.42.fr/pdf/pdf/113186/en.subject.pdf)**: La "bibbia" del progetto. Leggilo più e più volte, ogni dettaglio è importante. Contiene tutti i requisiti fondamentali, dalla struttura delle directory ai divieti sull'uso di `latest` e `--link`.

---

### 🐳 Docker: Fondamenti e Best Practices

*   **[Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)**: La guida definitiva per scrivere un Dockerfile. Copre ogni singola istruzione (`FROM`, `RUN`, `COPY`, `CMD`, `ENTRYPOINT`, `EXPOSE`, `VOLUME`, `USER`, `WORKDIR`). È un must per creare immagini personalizzate da zero.
*   **[Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)**: Il "galateo" di Docker. Spiega perché ottimizzare i layer per la cache, usare un `.dockerignore`, creare container "effimeri" e, cosa fondamentale, lanciare un solo processo per container in primo piano (foreground) per evitare hack come `tail -f` e rispettare il PID 1.
*   **[Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)**: Il manuale per orchestrare i servizi. Qui trovi come definire l'infrastruttura: `services`, `volumes` (named volumes), `networks`, `depends_on`, `restart: always` (fondamentale per i crash) e come usare le variabili d'ambiente.
*   **[Docker Volumes (Named Volumes)](https://docs.docker.com/storage/volumes/)**: Spiega come creare e gestire named volumes, fondamentali per la persistenza dei dati del database e dei file di WordPress. La sezione sui driver (`local` con `driver_opts`) è essenziale per mapparli fisicamente su `/home/login/data/`.
*   **[Docker Compose Environment Variables / `.env` file](https://docs.docker.com/compose/environment-variables/)**: Documentazione su come passare variabili d'ambiente a Docker Compose usando un file `.env` e l'istruzione `env_file` nel docker-compose.yml. Le password e le credenziali vanno qui, non nel codice o nei Dockerfile.
*   **[Docker Compose Secrets](https://docs.docker.com/compose/use-secrets/)**: Il metodo "fortemente raccomandato" dal subject per gestire informazioni sensibili. Invece di variabili d'ambiente, i segreti vengono montati come file read-only. Molto più sicuro.

---

### 🐧 Alpine Linux (Base OS Obbligatoria)

*   **[Alpine Package Keeper (`apk`)](https://wiki.alpinelinux.org/wiki/Alpine_Package_Keeper)**: La guida al package manager di Alpine. Usare `apk add --no-cache` nei Dockerfile è fondamentale per mantenere le immagini leggere e senza lasciare tracce di cache inutili. L'uso di `--no-cache` evita il layer intermedio di `apk update`, rendendo l'immagine più pulita.
*   **[Alpine Linux Releases](https://alpinelinux.org/releases/)**: Per scegliere la **penultimate stable version** richiesta dal progetto. Esempio: se l'ultima stabile è la 3.21, userai la 3.20.

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
*   **[How to Use the Command 'apk' (with Examples)](https://commandmasters.com/commands/apk-common/)**: Un riferimento pratico e veloce per i comandi `apk` più comuni, come `apk add`, `apk del`, `apk update`, `apk search`, `apk info` e altri utili durante la scrittura del Dockerfile.

---

### ⚙️ Processi e Automazione

*   **[GNU Make Manual](https://www.gnu.org/software/make/manual/)**: Per scrivere un Makefile solido con i target `all`, `up`, `down`, `clean`, `fclean`, `re`. Dovrà creare le directory dei volumi (es. `/home/login/data/wordpress`, `/home/login/data/mariadb`) e lanciare il `docker-compose up --build -d`.
*   **[Docker and the PID 1 Zombie Reaping Problem](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)**: (Non ufficiale ma fondamentale). Capire perché i container non sono VM e perché servono processi in foreground. Il processo con PID 1 deve gestire i segnali (`SIGTERM`) e i figli zombie. Spiega perché uno script di entrypoint deve terminare con `exec` per rimpiazzare la shell con il processo principale (es. `exec nginx -g 'daemon off;'`).
*   **[Official Docker Build Secrets Guide](https://www.hostinger.com/tutorials/docker-build-secrets)**: Una guida che spiega le best practice per non usare `ENV` o `ARG` per le password nei Dockerfile. Include la gestione dei segreti di build, utile se devi autenticarti per scaricare pacchetti durante la fase di `docker build` ed evitare che le credenziali rimangano nell'immagine finale.
