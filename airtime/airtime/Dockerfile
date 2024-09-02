FROM docker.io/ubuntu:trusty

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y \
      apache2 \
      curl \
      gettext-base \
      git \
      python \
      python-pip \
      rabbitmq-server \
      supervisor \
      unzip \
      wget \
      ; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    TMPDIR=$(mktemp -d); \
    cd ${TMPDIR}; \
    for i in \
      https://files.pythonhosted.org/packages/cc/a4/f265c6f9a7eb1dd45d36d9ab775520e07ff575b11ad21156f9866da047b2/amqp-1.4.9.tar.gz \
      https://files.pythonhosted.org/packages/75/b7/8c2429bf8d92354a0118614f9a4d15e53bc69ebedce534284111de5a0102/amqplib-1.0.2.tgz \
      https://files.pythonhosted.org/packages/c3/4d/d4089e1a3dd25b46bebdb55a992b0797cff657b4477bc32ce28038fdecbc/anyjson-0.3.3.tar.gz \
      https://files.pythonhosted.org/packages/6f/ad/86448942ad49c5fe05bfdf7ebc874807f521dfcca5ee543afaca2974ad5a/argparse-1.2.1.tar.gz \
      https://files.pythonhosted.org/packages/64/61/079eb60459c44929e684fa7d9e2fdca403f67d64dd9dbac27296be2e0fab/configobj-5.0.6.tar.gz \
      https://files.pythonhosted.org/packages/a2/55/8f8cab2afd404cf578136ef2cc5dfb50baa1761b68c9da1fb1e4eed343c9/docopt-0.6.2.tar.gz \
      https://files.pythonhosted.org/packages/bb/41/563d20ed360dd11636b8fb29a6809ffd83bac1fef61158e4bf08c29b316d/kombu-3.0.34.tar.gz \
      https://files.pythonhosted.org/packages/8c/1a/ae4db593055f738ee115485ca1261b1e6e83385a61fea5dc84e8e5702dcc/mutagen-1.31.tar.gz \
      https://files.pythonhosted.org/packages/9f/dc/0683a458d21c3d561ab2f71b4fcdd812bf04e55c54e560b0854cea95610e/poster-0.8.1.tar.gz \
      https://files.pythonhosted.org/packages/cd/37/39aca520918ce1935bea9c356bcbb7ed7e52ad4e31bff9b943dfc8e7115b/PyDispatcher-2.0.5.tar.gz \
      https://files.pythonhosted.org/packages/e3/c0/fd5b18dde17c1249658521f69598f3252f11d9d7a980c5be8619970646e1/pyinotify-0.9.6.tar.gz \
      https://files.pythonhosted.org/packages/bf/fb/80ad342d76e4a3d2e0f3398ab3ebeeb0c98551beae4fbca068c699bf42d1/pytz-2015.7.tar.gz \
      https://files.pythonhosted.org/packages/d1/0c/2dc2996268bc64b531a5a2dc6f4ec04552f3a8a2a86e88aeedcb92987741/requests-2.2.1.tar.gz \
      https://files.pythonhosted.org/packages/41/9e/309259ce8dff8c596e8c26df86dbc4e848b9249fd36797fd60be456f03fc/wsgiref-0.1.2.zip \
      ; do \
      wget $i; \
    done; \
    for i in *.tgz *.tar.gz; do \
      tar -xzf $i; \
    done; \
    for i in *.zip; do \
      unzip $i; \
    done; \
    for i in $(find * -type d -maxdepth 0); do \
      cd $i; \
      python setup.py install; \
      cd ..; \
    done; \
    cd; \
    rm -rf ${TMPDIR}

RUN set -eux; \
    apachectl start; \
    rabbitmq-server -detached; \
    TMPDIR=$(mktemp -d); \
    cd ${TMPDIR}; \
    git clone --depth 1 --single-branch --branch=2.5.x https://github.com/sourcefabric/airtime.git; \
    cd airtime; \
    ./install -fiap; \
    install -d -o www-data -g www-data -m 0755 /srv/airtime/stor; \
    cd; \
    rm -rf ${TMPDIR}

COPY airtime.conf.tmpl /etc/airtime/airtime.conf.tmpl
COPY locale /etc/default/locale
COPY supervisord.conf /etc/supervisor/conf.d/airtime.conf
COPY airtime-update-db-settings /usr/local/bin/airtime-update-db-settings
COPY entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY json.xsl /usr/share/icecast2/web/json.xsl

VOLUME /srv/airtime/stor
EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["supervisord", "-n"]
