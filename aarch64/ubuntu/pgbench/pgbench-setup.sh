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
which psql
psql --version
mkdir -p $HOME/pgdata-unpatched
initdb --pgdata=$HOME/pgdata-unpatched --encoding=UTF8
pg_ctl -D $HOME/pgdata-unpatched -l $HOME/logfile-unpatched start
createdb -O pgsql psql
createdb -O pgsql arm
createdb -O pgsql postgres || true
createdb -O pgsql pgsql
./vm.sh

cd ~/code-patched/postgres
./configure --prefix=$HOME/pg-install-patched/ ; make -j ; make install
export PATH=$PATH:$HOME/pg-install-patched/bin
which psql
psql --version
mkdir -p $HOME/pgdata-patched
initdb --pgdata=$HOME/pgdata-patched --encoding=UTF8
pg_ctl -D $HOME/pgdata-patched -l $HOME/logfile-patched start
createdb -O pgsql psql
createdb -O pgsql arm
createdb -O pgsql postgres || true
createdb -O pgsql pgsql
./vm.sh
