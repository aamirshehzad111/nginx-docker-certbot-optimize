#!/bin/sh


#$(ln -s /etc/nginx/sites-available/eurustech.conf /etc/nginx/sites-enabled/eurustech.conf)


if [[ ! -f /var/www/certbot ]]; then
    mkdir -p /var/www/certbot
fi


if [[ ! -f /var/www/hrm/public_html ]]; then
    mkdir -p /var/www/hrm/public_html
    echo '<h2> Hy working hrm site!! </h2>' > /var/www/hrm/public_html/index.html 
    echo '<h2>nginx eurusrechnolgysite -- </h2>' > /usr/share/nginx/html/index.html 
fi

$(ln -s /etc/nginx/sites-available/hrm.conf /etc/nginx/sites-enabled/hrm.conf)
$(nginx -t)
$(nginx -s reload)


certbot certonly \
        --config-dir "${LETSENCRYPT_DIR:-/etc/letsencrypt}" \
		--agree-tos \
		--email "aamir@eurustechnologies.com" \
		--expand \
		--noninteractive \
		--webroot \
		--webroot-path /var/www/certbot \
                --domains "$DOMAIN" \
		$OPTIONS || true

if [[ -f "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/"$DOMAIN"/privkey.pem" ]]; then
    cp "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/"$DOMAIN"/privkey.pem" /usr/share/nginx/certificates/privkey.pem
    cp "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/"$DOMAIN"/fullchain.pem" /usr/share/nginx/certificates/fullchain.pem

fi


certbot certonly \
        --config-dir "${LETSENCRYPT_DIR:-/etc/letsencrypt}" \
		--agree-tos \
		--email aamir@eurustechnologies.com \
		--expand \
		--noninteractive \
		--webroot \
		--webroot-path /var/www/certbot \
                --domains "$DOMAIN2" \
		$OPTIONS || true

if [[ -f "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/"$DOMAIN2"/privkey.pem" ]]; then
    cp "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/"$DOMAIN2"/privkey.pem" /usr/share/nginx/certificates/privkeyy.pem
    cp "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/"$DOMAIN2"/fullchain.pem" /usr/share/nginx/certificates/fullchainn.pem

fi

