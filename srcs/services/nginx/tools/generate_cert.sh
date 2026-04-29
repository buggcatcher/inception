questo file servirá a generare un certificato TLS self‑signed al primo avvio del container, se non esiste già.



    Il subject richiede che NGINX ascolti solo su porta 443 con TLSv1.2 o TLSv1.3.
    Non puoi mettere il certificato nel repository (né nel Dockerfile) perché sarebbe pubblico e non rigenerabile.
    Inoltre, la generazione deve avvenire all'avvio, non durante il docker build, altrimenti il certificato sarebbe lo stesso per tutte le istanze.

Esempio minimo:

#!/bin/sh
set -e
if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=IT/ST=./L=./O=42/CN=${DOMAIN_NAME}"
fi
# Poi il container avvia nginx (il Dockerfile chiamerà questo script prima di nginx)

---

Nel Dockerfile di nginx:
dockerfile

COPY tools/generate_cert.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate_cert.sh
CMD ["sh", "-c", "generate_cert.sh && nginx -g 'daemon off;'"]