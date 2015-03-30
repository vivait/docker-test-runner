# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
FROM lewisw/baseimage-docker
MAINTAINER Lewis Wright <lewis@allwrightythen.com>

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
&& [ "$GITHUB_OAUTH_TOKEN" != ""] && composer config -g github-oauth.github.com $GITHUB_OAUTH_TOKEN

# Install various scripts
COPY scripts/ .
RUN chmod +x ansible_* \
 && chmod +x composer_setup \
 && chmod +x graceful_shutdown

COPY init/ /etc/my_init.d/
RUN chmod +x /etc/my_init.d/*

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
