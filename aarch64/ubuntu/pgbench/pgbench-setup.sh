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


#yum -y install gcc gcc-c++ automake zlib zlib-devel bzip2 bzip2-devel bzip2- libs readline readline-devel bison gmp gmp-devel mpfr mpfr-devel libmpc libmpc-devel 
apt-get install zlib1g zlib1g-dev bzip2 libbz2-dev readline-common libreadline-dev bison libgmp-dev libmpfr-dev libmpc-dev -y
apt-get install flex -y
useradd -m -d /home/pgsql -s /bin/bash pgsql && echo pgsql:pgsql | chpasswd && adduser pgsql sudo
echo "pgsql ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


## pguser
cd
mkdir code
cd code
git clone https://github.com/postgres/postgres.git
cd postgres
./configure --prefix=$HOME/pg-install/ ; make -j ; make install
cd
git clone https://github.com/mysqlonarm/benchmark-suites.git
ls
cd benchmark-suites/
export PATH=$PATH:$HOME/pg-install/bin
which psql
psql --version
mkdir -p $HOME/pgdata
initdb --pgdata=$HOME/pgdata --encoding=UTF8
pg_ctl -D $HOME/pgdata -l $HOME/logfile start
createdb -O pgsql psql
createdb -O pgsql arm
createdb -O pgsql postgres || true
createdb -O pgsql pgsql
./vm.sh
