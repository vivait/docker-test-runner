# This Dockerfile is used to build an image containing basic stuff to be used as a docker test runner
FROM docker.vivait.co.uk/baseimage-docker
MAINTAINER Viva IT <enquiry@vivait.co.uk>

# Fix Docker's bad handling of spare files
RUN rm -f /var/log/lastlog && \
    ln -s /dev/null /var/log/lastlog

# this forces dpkg not to call sync() after package extraction and speeds up install
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup

# we don't need an apt cache in a container
RUN { \
  aptGetClean='"rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true";'; \
  echo "DPkg::Post-Invoke { ${aptGetClean} };"; \
  echo "APT::Update::Post-Invoke { ${aptGetClean} };"; \
  echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";'; \
} > /etc/apt/apt.conf.d/no-cache && apt-get update


# and remove the translations, too
RUN echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/no-languages

# Setting ENV HOME does not seem to work currently. HOME is unset in Docker container.
# See bug : https://github.com/phusion/baseimage-docker/issues/119
ENV HOME /root
# Workaround:
RUN echo /root > /etc/container_environment/HOME

ENV DEBIAN_FRONTEND="noninteractive" DEBCONF_NONINTERACTIVE_SEEN=true

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
 && pip install ansible==1.9.3 markupsafe \
 && mkdir -p /usr/share/ansible_plugins/callback_plugins \
 && cd /usr/share/ansible_plugins/callback_plugins \
 && curl -O https://raw.githubusercontent.com/jlafon/ansible-profile/3fa119f29306a319eb414f00de309ea5a2fad0df/callback_plugins/profile_tasks.py \
 && mkdir /etc/ansible \
 && echo "[defaults]\nforce_color = 1" > /etc/ansible/ansible.cfg

RUN apt-get install -y --no-install-recommends \
        # Install PHP tools
        php5-cli \
        php5-curl \
        git \
&& curl https://getcomposer.org/installer | php \
&& mv composer.phar /usr/local/bin/composer

RUN curl -O https://raw.githubusercontent.com/maartenba/phpunit-runner-teamcity/f225b7d83799d2661793e3bb23ed300943d60c0f/phpunit-tc.php

# Install various scripts
COPY scripts/ .
RUN chmod +x ansible_* \
 && chmod +x composer_setup \
 && chmod +x graceful_shutdown \
 && chmod +x apt_cacher \
 && chmod +x composer_oauth \
 && chmod +x initctl_faker

COPY init/ /etc/my_init.d/
RUN chmod +x /etc/my_init.d/*

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV MYSQL_DB="/var/lib/mysql/" MYSQL_HOME="/mysql"

COPY files/tmpfs.cnf /etc/mysql/conf.d/tmpfs.cnf
RUN chmod 664 /etc/mysql/conf.d/tmpfs.cnf

RUN rm -fr /sbin/initctl && ln -s /initctl_faker /sbin/initctl

#Needed so that www-data can restart worker services in tests
RUN echo "www-data ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

ENTRYPOINT ["/usr/bin/eatmydata", "/sbin/my_init"]
