FROM nginx:1.15-alpine 
RUN apk add inotify-tools certbot openssl ca-certificates
ENV DOMAIN = eurustechnology1.scaleops.info
ENV DOMAIN2 = hrmeurustech1.scaleops.info
WORKDIR /opt
COPY entrypoint.sh nginx-letsencrypt
COPY certbot.sh certbot.sh
COPY ssl-options/ /etc/ssl-options
COPY nginx.conf /etc/nginx/
RUN chmod +x nginx-letsencrypt && \
    chmod +x certbot.sh 
RUN mkdir /etc/nginx/sites-available
RUN mkdir /etc/nginx/sites-enabled
ENTRYPOINT ["./nginx-letsencrypt"]

