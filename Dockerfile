FROM php:7.0-apache
MAINTAINER Christian Simon <mail@christiansimon.eu>

ENV POSTFIXADMIN_VERSION 3.2

RUN echo "courier-base courier-base/webadmin-configmode boolean true" | debconf-set-selections

# install the tools and PHP extensions we need
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y libcurl4-gnutls-dev libpng-dev libssl-dev libc-client2007e-dev libkrb5-dev unzip cron re2c python tree wget sudo \
  && apt-get install -y --no-install-recommends courier-base \
  && docker-php-ext-configure imap --with-imap-ssl --with-kerberos \
  && docker-php-ext-install mysqli curl gd zip mbstring imap iconv \
  && rm -rf /var/lib/apt/lists/* \
  && echo 'date.timezone="Europe/Berlin"' >> /usr/local/etc/php/conf.d/postfixadmin.ini

ENV DL_URL "https://sourceforge.net/projects/postfixadmin/files/postfixadmin/postfixadmin-${POSTFIXADMIN_VERSION}/postfixadmin-${POSTFIXADMIN_VERSION}.tar.gz/download?use_mirror=freefr"

RUN cd /var/www/html \
  && wget "${DL_URL}" -O postfixadmin-${POSTFIXADMIN_VERSION}.tar.gz \
  && tar -xvzf postfixadmin-${POSTFIXADMIN_VERSION}.tar.gz --strip-components=1 \
  && rm postfixadmin-${POSTFIXADMIN_VERSION}.tar.gz \
  && chown -R www-data:www-data .

COPY postfixadmin-mailbox-postcreation.sh /usr/local/bin/postfixadmin-mailbox-postcreation.sh

RUN chmod a+x /usr/local/bin/postfixadmin-mailbox-postcreation.sh \
  && groupadd -r --gid 5000 vmail \
  && useradd -r --uid 5000 -g vmail -d /var/vmail -s /bin/false -m vmail \
  && echo "www-data ALL = (vmail)NOPASSWD: /usr/local/bin/postfixadmin-mailbox-postcreation.sh" >> /etc/sudoers