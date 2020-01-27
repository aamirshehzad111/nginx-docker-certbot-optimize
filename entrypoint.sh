#!/bin/sh
# Create a self signed default certificate, so Ngix can start before we have
# any real certificates.

#Ensure we have folders available

if [[ ! -f /usr/share/nginx/certificates/fullchain.pem ]];then
    mkdir -p /usr/share/nginx/certificates
fi

if [[ ! -f /usr/share/nginx/certificates/cert.crt ]]; then
    openssl genrsa -out /usr/share/nginx/certificates/privkey.pem 4096
    openssl req -new -key /usr/share/nginx/certificates/privkey.pem -out /usr/share/nginx/certificates/cert.csr -nodes -subj \
    "/C=PT/ST=World/L=World/O=${DOMAIN:-ilhicas.com}/OU=Ilhicas/CN=${DOMAIN:-ilhicas.com}/EMAIL=${EMAIL:-info@ilhicas.com}"
    openssl x509 -req -days 365 -in /usr/share/nginx/certificates/cert.csr -signkey /usr/share/nginx/certificates/privkey.pem -out /usr/share/nginx/certificates/fullchain.pem

    openssl genrsa -out /usr/share/nginx/certificates/privkeyy.pem 4096
    openssl req -new -key /usr/share/nginx/certificates/privkeyy.pem -out /usr/share/nginx/certificates/certt.csr -nodes -subj \
    "/C=PT/ST=World/L=World/O=${DOMAIN2:-ilhicas.com}/OU=Ilhicas/CN=${DOMAIN2:-ilhicas.com}/EMAIL=${EMAIL:-info@ilhicas.com}"
    openssl x509 -req -days 365 -in /usr/share/nginx/certificates/certt.csr -signkey /usr/share/nginx/certificates/privkeyy.pem -out /usr/share/nginx/certificates/fullchainn.pem

fi

### Send certbot Emission/Renewal to background
$(while :; do /opt/certbot.sh; sleep "${RENEW_INTERVAL:-12h}"; done;) &

### Check for changes in the certificate (i.e renewals or first start)
$(while inotifywait -e close_write /usr/share/nginx/certificates; do nginx -s reload; done) &

nginx -g "daemon off;"


