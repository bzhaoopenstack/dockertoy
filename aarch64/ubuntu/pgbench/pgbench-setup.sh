## root
apt-get -q update \
    && apt-get -q install -y --no-install-recommends \
        build-essential \
        autoconf \
        automake \
        libtool \
        cmake \
        zlib1g-dev \
        pkg-config \
        libssl-dev \
        libssl1.0.0 \
        libsasl2-dev \
        bats \
        curl \
        sudo \
        git \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# yum update -y && \
#    yum -y install bison ncurses ncurses-devel libaio-devel openssl openssl-devel gmp gmp-devel mpfr mpfr-devel libmpc libmpc-devel git wget which && \
#    yum groupinstall "Development Tools" -y


#yum -y install gcc gcc-c++ automake zlib zlib-devel bzip2 bzip2-devel bzip2- libs readline readline-devel bison gmp gmp-devel mpfr mpfr-devel libmpc libmpc-devel 
# yum -y install readline-devel
apt-get install zlib1g zlib1g-dev bzip2 libbz2-dev readline-common libreadline-dev bison libgmp-dev libmpfr-dev libmpc-dev -y
apt-get install flex -y
useradd -m -d /home/pgsql -s /bin/bash pgsql && echo pgsql:pgsql | chpasswd && adduser pgsql sudo
echo "pgsql ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


## pguser
cd
git clone https://github.com/mysqlonarm/benchmark-suites.git
ls

mkdir code-base
cd code-base
git clone https://github.com/postgres/postgres.git
mkdir ~/code-patched
mkdir ~/code-unpatched
cp -rf ./postgres ~/code-patched/
cp -rf ./postgres ~/code-unpatched/
cd ~/code-unpatched/postgres
./configure --prefix=$HOME/pg-install-unpatched/ ; make -j ; make install

cd

export PATH=$PATH:$HOME/pg-install-unpatched/bin
export PGSQL_BASE_DIR=$HOME/pg-install-unpatched/
export PG_USER=pgsql

# for sysbench, you need to install the latest sysbench package, do not use apt install to install the sysbench.
which psql
psql --version
mkdir -p $HOME/pgdata-unpatched
initdb --pgdata=$HOME/pgdata-unpatched --encoding=UTF8
pg_ctl -D $HOME/pgdata-unpatched -l $HOME/logfile-unpatched start
createdb -O pgsql psql
createdb -O pgsql arm
# X86
# createdb -O pgsql x86
createdb -O pgsql postgres || true
createdb -O pgsql pgsql
# for pgbench, before running it, you need to exec "pgbench -i" to init the test tables or constructions.
pgbench -i arm
# X86
# pgbench -i x86

cd ~/benchmark-suites/pgsql-pbench
export PGSQL_BASE_DIR=$HOME/pg-install-unpatched/
./vm.sh


# sysbench
#cd && \
#    git clone https://github.com/akopytov/sysbench.git && \
#	cd sysbench && \
#	./autogen.sh && \
#	./configure --with-pgsql-includes=$HOME/pg-install-unpatched/include --with-pgsql-libs=$HOME/pg-install-unpatched/lib/ --prefix=$HOME/sysbench-install-unpatched/ --with-pgsql --without-mysql && \
#	make -j && \
#	make install
# export PATH=$PATH:$HOME/sysbench-install-unpatched/bin/


# ./configure --with-mysql-includes=$HOME/pg-install-unpatched/include --with-mysql-libs=$HOME/pg-install-unpatched/lib/ --prefix=$HOME/sysbench-install-unpatched/ --with-mysql

cd ~/code-patched/postgres
./configure --prefix=$HOME/pg-install-patched/ ; make -j ; make install
export PATH=$PATH:$HOME/pg-install-patched/bin
export PGSQL_BASE_DIR=$HOME/pg-install-patched/
export PG_USER=pgsql

# for sysbench, you need to install the latest sysbench package, do not use apt install to install the sysbench.
which psql
psql --version
mkdir -p $HOME/pgdata-patched
initdb --pgdata=$HOME/pgdata-patched --encoding=UTF8
pg_ctl -D $HOME/pgdata-patched -l $HOME/logfile-patched start
createdb -O pgsql psql
createdb -O pgsql arm
# X86
# createdb -O pgsql x86
createdb -O pgsql postgres || true
createdb -O pgsql pgsql
# for pgbench, before running it, you need to exec "pgbench -i" to init the test tables or constructions.
pgbench -i arm
# X86
# pgbench -i x86
cd ~/benchmark-suites/pgsql-pbench
export PGSQL_BASE_DIR=$HOME/pg-install-patched/
./vm.sh
