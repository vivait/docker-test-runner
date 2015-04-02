# This Dockerfile is used to build an image containing basic stuff to be used as a docker test runner
FROM lewisw/baseimage-docker
MAINTAINER Lewis Wright <lewis@allwrightythen.com>

# this forces dpkg not to call sync() after package extraction and speeds up install
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup

# we don't need an apt cache in a container
RUN { \
  aptGetClean='"rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true";'; \
  echo "DPkg::Post-Invoke { ${aptGetClean} };"; \
  echo "APT::Update::Post-Invoke { ${aptGetClean} };"; \
  echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";'; \
  echo 'Acquire::http {No-Cache=True;};'; \
} > /etc/apt/apt.conf.d/no-cache

# and remove the translations, too
RUN echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/no-languages

# Setting ENV HOME does not seem to work currently. HOME is unset in Docker container.
# See bug : https://github.com/phusion/baseimage-docker/issues/119
ENV HOME /root
# Workaround:
RUN echo /root > /etc/container_environment/HOME

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

# Install ansible
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        eatmydata\
        curl\
        # Install python tools
        python-setuptools\
        python-dev\
        python-apt\
        build-essential\
        software-properties-common\
 && easy_install pip \
 && pip install ansible markupsafe \
 && mkdir /etc/ansible \
 && echo "[defaults]\nforce_color = 1" > /etc/ansible/ansible.cfg

RUN apt-get install -y --no-install-recommends \
        # Install PHP tools
        php5-cli \
        php5-curl \
        git \
&& curl https://getcomposer.org/installer | php \
&& mv composer.phar /usr/local/bin/composer

# Install various scripts
COPY scripts/ .
RUN chmod +x ansible_* \
 && chmod +x composer_setup \
 && chmod +x graceful_shutdown

COPY init/ /etc/my_init.d/
RUN chmod +x /etc/my_init.d/*

RUN [ -f github-oauth.token ] && composer config -g github-oauth.github.com `cat github-oauth.token`

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV MYSQL_DB="/var/lib/mysql/" MYSQL_HOME="/mysql"

ENTRYPOINT ["/usr/bin/eatmydata", "/sbin/my_init"]
