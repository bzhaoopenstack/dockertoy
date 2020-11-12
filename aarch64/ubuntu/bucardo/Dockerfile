FROM ubuntu:bionic

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

######
# Install common dependencies from packages. Versions here are either
# sufficient or irrelevant.
# WARNING: DO NOT PUT JAVA APPS HERE! Otherwise they will install default
# Ubuntu Java.  See Java section below!
######
RUN apt-get -q update \
    && apt-get -q install -y --no-install-recommends \
        build-essential \
        ccache \
        libevent-dev \
        libapr1-dev \
        libffi-dev \
        libssl-dev \
        git \
        python-pip \
        python-dev \
        gcc \
        libsodium-dev \
        libcurl4-openssl-dev \
        libzstd1-dev \
        libldap2-dev \
        flex \
        libbz2-dev \
        bison \
        libpq-dev \
        postgresql-server-dev-all \
        postgresql-common \
        libyaml-dev \
        zlib1g \
        zlib1g-dev \
        sudo \
        vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get install zlib1g zlib1g-dev bzip2 libbz2-dev readline-common libreadline-dev bison libgmp-dev libmpfr-dev libmpc-dev -y

######
# Create test user with sudo priority
######
RUN useradd -m -d /home/bucardo -s /bin/bash bucardo && echo bucardo:bucardo | chpasswd && adduser bucardo sudo
RUN echo "bucardo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER bucardo
WORKDIR /home/bucardo

ENV PGVERSION 10

RUN sudo apt-get install -y \
    postgresql-${PGVERSION} \
    postgresql-client-${PGVERSION} \
    postgresql-${PGVERSION}-pgtap \
    postgresql-server-dev-${PGVERSION} \
    postgresql-server-dev-all \
    postgresql-plperl-${PGVERSION} \
    debhelper fakeroot libdbd-pg-perl libtap-parser-sourcehandler-pgtap-perl

RUN sudo apt-get install perl cpanminus -y

RUN git clone https://github.com/bucardo/bucardo.git

ENV PATH /usr/lib/postgresql/${PGVERSION}/bin:${PATH}

RUN cd ~/bucardo && \
    cpanm --version && \
    cpanm --installdeps --notest . && \
    sudo cpanm --installdeps --notest . && \
    sudo cpan install DBD::Pg && \
    sudo cpan install DBI && \
    sudo cpan install DBIx::Safe && \
    perl Makefile.PL

RUN cd ~/bucardo && \
    BUCARDO_LOG_ERROR_CONTEXT=1 PATH=$PATH:/usr/lib/postgresql/${PGVERSION}/bin make test || true

RUN cat ~/bucardo/log.context
