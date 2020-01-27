The problem is that we need to install lets-Encrypt certificate in nginx Container of Docker.

There are two solutions that address this problem.

1 - Two conatiner one is of nginx and another certbot. 

2 - Nginx and Let's Encrypt/certbot inside single Container of Docker.

We are going to use second approch.

Steps are mentioned below.

* Since we will be using nginx we must first start by using an official docker image for nginx, we will also need certbot to create the acme challenges required to have valid certificates, and a few others.

        FROM nginx:1.15-alpine 
        RUN apk add inotify-tools certbot openssl
        WORKDIR /opt
        COPY entrypoint.sh nginx-letsencrypt
        COPY certbot.sh certbot.sh
        COPY default.conf /etc/nginx/conf.d/default.conf
        COPY ssl-options/ /etc/ssl-options
        RUN chmod +x nginx-letsencrypt && \
            chmod +x certbot.sh 
        ENTRYPOINT ["./nginx-letsencrypt"]

* Packages Details:
    1) inotify-tools so we have access to inotifywait to watch our certificates and trigger some actions when they change.
    2) We will need openssl to provide dummy certificate to nginx so that hen nginx starts so it doesn’t complain about       the missing certificates.
    3) Certbot is what we will need to actually emit valid ssl certificates.

* Scripts Details:
    1) entypoint.sh, it does following actions:

        * Create a self signed default certificate, so Ngix can start before we have any real certificates. 
        * Send certbot Renewal Process to background (Renewal process run after every 12 hours).
        * Check for changes using inotify-tools in the certificate (i.e renewals or first start) and send this process to    background too.
        * Start nginx with daemon off.

                #!/bin/sh

                if [[ ! -f /usr/share/nginx/certificates/fullchain.pem ]];then
                    mkdir -p /usr/share/nginx/certificates
                fi

                if [[ ! -f /usr/share/nginx/certificates/fullchain.pem ]]; then
                    openssl genrsa -out /usr/share/nginx/certificates/privkey.pem 4096
                    sl genrsa -out /usr/share/nginx/certificates/privkey.pem 4096
                    openssl req -new -key /usr/share/nginx/certificates/privkey.pem -out /usr/share/nginx/certificates/cert.csr -nodes -subj \
                    "/C=PT/ST=World/L=World/O=${DOMAIN:-ilhicas.com}/OU=ilhicas lda/CN=${DOMAIN:-ilhicas.com}/EMAIL=${EMAIL:-info@ilhicas.com}"
                    openssl x509 -req -days 365 -in /usr/share/nginx/certificates/cert.csr -signkey /usr/share/nginx/certificates/privkey.pem -out /usr/share/nginx/certificates/fullchain.pem
                fi

                $(while :; do /opt/certbot.sh; sleep "${RENEW_INTERVAL:-12h}"; done;) &

                $(while inotifywait -e close_write /usr/share/nginx/certificates; do nginx -s reload; done) &

                nginx -g "daemon off;"


    2) certbot.sh, it does following actions:
        
        * Given below Script is running in the background every 12 hours by default, and its responsible for emiting and     renewing the certificates, copying them from the letsencrypt folder to the location nginx will be using to serve.

        * --webroot-path (location for the acme-challenge), and this is the folder where certbot will create the             challenges files to prove ownership of domain. 

                if [[ ! -f /var/www/certbot ]]; then
                mkdir -p /var/www/certbot
                fi
                certbot certonly \
                        --config-dir "${LETSENCRYPT_DIR:-/etc/letsencrypt}" \
                        --agree-tos \
                        --domains "$DOMAIN" \
                        --email "$EMAIL" \
                        --expand \
                        --noninteractive \
                        --webroot \
                        --webroot-path /var/www/certbot \
                        $OPTIONS || true

                if [[ -f "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/$DOMAIN/privkey.pem" ]]; then
                    cp "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/$DOMAIN/privkey.pem" /usr/share/nginx/certificates/privkey.pem
                    cp "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/$DOMAIN/fullchain.pem" /usr/share/nginx/certificates/fullchain.pem
                fi
    
    3) Some points:

        * This script will be generating a single certificate for a domain. 

        * If you want to generate two certificate for two domains, you gotta run 'certbot certonly' command two times with   two different domain.

        * Alternatively you want to use one certificate for multiple domains, you just need to change --domains option. 
                e.g  -- domains exemple.com checkthis.com example2.info
        
        * To generate wildcard certificate Details are provided at the end of this Readme.md file.

* Whenever certbot runs, it will ask letsencrypt to come to the domain under that location to validate the challenge,        that’s why its important to have nginx already running when certbot runs, and why we need to already have dummy            certificates at the chosen location for it to start.

* Build Docker image and run container. provide domain name and email and can also provide nginx.conf file. 


* To obtain wildcard certificate, Let's Encrypt supports wildcard certificate via ACMEv2 using the DNS-01 challenge.            
    * Certbot provides --manual option to perform it. 
    * All that is necessary in addition is to add a TXT record specified by Certbot to the DNS server.

            if [[ ! -f /var/www/scaleops ]]; then
                 mkdir -p /var/www/scaleops
            fi

            certbot certonly \
                --server "https://acme-v02.api.letsencrypt.org/directory" \
                --manual \
                --agree-tos \
                --expand \
                --preferred-challenges dns \
                --manual-public-ip-logging-ok \
                -d *.scaleops.info \
                --config-dir "${LETSENCRYPT_DIR:-/etc/letsencrypt}" \

            if [[ -f "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/scaleops.info/privkey.pem" ]]; then
                cp "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/scaleops.info/privkey.pem"  /usr/share/nginx/certificates/privkeyy.pem
                cp "${LETSENCRYPT_DIR:-/etc/letsencrypt}/live/scaleops.info/fullchain.pem" /usr/share/nginx/certificates/fullchainn.pem

            fi
            
            #echo -e  '2' '\n' | /opt/certbot.sh 


    * In order to revew Let's Encrypt wildcard certificates (DNS-01 challenge) with certbot, all what we need to do,     is to follow the same process of the first time.
