questo file servirá ad installare e configurare WordPress solo la prima volta (scarica WordPress tramite wp‑cli, crea wp-config.php, esegue l'installazione con utente admin, aspetta che MariaDB sia pronto), poi avvia php-fpm in foreground.


    WordPress ha bisogno di connettersi a MariaDB, ma MariaDB potrebbe non essere ancora pronto all'avvio del container WordPress.
    Lo script attende attivamente MariaDB (con un loop nc -z) prima di procedere.
    Una volta installato, non deve reinstallare a ogni riavvio (controlla se wp-config.php esiste).
    Infine lancia php‑fpm con exec in foreground.
    Rispetta il divieto di tail -f e simili.

Esempio minimo (wp_setup.sh):

#!/bin/bash
set -e

# Attendi MariaDB
while ! nc -z mariadb 3306; do
    sleep 1
done

cd /var/www/html

if [ ! -f wp-config.php ]; then
    wp core download --allow-root
    wp config create --dbname="$MYSQL_DATABASE" --dbuser="$MYSQL_USER" --dbpass="$MYSQL_PASSWORD" --dbhost="mariadb" --allow-root
    wp core install --url="https://${DOMAIN_NAME}" --title="Inception" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL" --allow-root
    wp user create "$WP_USER" "$WP_USER_EMAIL" --role=editor --user_pass="$WP_USER_PASSWORD" --allow-root
fi

exec php-fpm83 -F

---

Nel Dockerfile di wordpress:
dockerfile

COPY tools/wp_setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp_setup.sh
CMD ["/usr/local/bin/wp_setup.sh"]