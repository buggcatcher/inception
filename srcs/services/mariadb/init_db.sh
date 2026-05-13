Questo file servirá ad inizializzare il database al primo avvio – creare la directory dei dati, avviare temporaneamente MariaDB, eseguire le query SQL per creare database, utenti e permessi, poi fermare il processo temporaneo e riavviare MariaDB in foreground.



    Il database deve essere persistente (volume named), ma la prima volta che parte la directory /var/lib/mysql è vuota.
    Devi creare il database wordpress, l'utente WordPress, e impostare la password di root.
    Non puoi farlo nel Dockerfile perché il volume viene montato dopo la build.
    Il subject vieta hack come tail -f, quindi lo script deve terminare lanciando mysqld in foreground con exec.


Esempio minimo:

#!/bin/bash
set -e

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Avvia mysqld in background temporaneamente
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
pid="$!"

# Attendi che sia pronto
while ! mysqladmin ping -h localhost --silent; do
    sleep 1
done

# Esegui le query di inizializzazione
mysql -uroot <<-EOSQL
    CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    FLUSH PRIVILEGES;
EOSQL

# Ferma il processo temporaneo
mysqladmin -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait "$pid"

# Avvia mysqld in foreground (PID 1)
exec mysqld --user=mysql --datadir=/var/lib/mysql

---

Nel Dockerfile di mariadb:
dockerfile

COPY tools/init_db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_db.sh
CMD ["/usr/local/bin/init_db.sh"]