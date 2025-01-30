ARG ALPINE_VERSION=3.21
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Adam S. Leven <addohm@hotmail.com>"
LABEL Description="Lightweight container with Nginx 1.26, PHP 8.4 & msmtp based on Alpine Linux.  This is derived from Tim de Pater's original work creating the nginx and php84 image."

# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php84 \
  php84-ctype \
  php84-curl \
  php84-dom \
  php84-fileinfo \
  php84-fpm \
  php84-gd \
  php84-intl \
  php84-mbstring \
  php84-mysqli \
  php84-opcache \
  php84-openssl \
  php84-phar \
  php84-session \
  php84-tokenizer \
  php84-xml \
  php84-xmlreader \
  php84-xmlwriter \
  php84-pecl-xdebug \
  supervisor \
  msmtp \
  ca-certificates 

# Setup the config file directory
ENV CONFDIR=/var/www/config
RUN mkdir ${CONFDIR}

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
RUN ln -s ${CONFDIR}/nginx.conf /etc/nginx/http.d/server.conf

# Configure nginx - default server
COPY config/conf.d /etc/nginx/http.d/

# Setup the php ini directory
ENV PHP_INI_DIR=/etc/php84

# Configure PHP
COPY config/php.ini ${PHP_INI_DIR}/conf.d/custom.ini
RUN ln -s ${CONFDIR}/php.ini /etc/php84/conf.d/settings.ini

# Configure PHP-FPM
COPY config/fpm-pool.conf ${PHP_INI_DIR}/php-fpm.d/www.conf
RUN ln -s ${CONFDIR}/php-fpm.conf /etc/php84/php-fpm.d/server.conf

# Configure msmtp
ENV SYSCONFDIR=/etc/msmtp
RUN ln -s ${CONFDIR}/msmtp.conf /etc/msmtprc

# Add configuration
COPY config/xdebug.ini ${PHP_INI_DIR}/conf.d/xdebug.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody:nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1