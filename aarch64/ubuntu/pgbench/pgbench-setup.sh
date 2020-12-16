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
useradd -m -d /home/greenplum -s /bin/bash greenplum && echo greenplum:greenplum | chpasswd && adduser greenplum sudo
echo "greenplum ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


## pguser
cd
git clone https://github.com/postgres/postgres.git
cd postgres
./configure --prefix=/home/greenplum/pg-install/ ; make -j ; make install
cd ../
git clone https://github.com/mysqlonarm/benchmark-suites.git
ls
cd benchmark-suites/
export PATH=$PATH:/home/greenplum/pg-install/bin
which psql
psql --version
mkdir -p /home/greenplum/pgdata
initdb --pgdata=/home/greenplum/pgdata --encoding=UTF8
pg_ctl -D /home/greenplum/pgdata -l /home/greenplum/logfile start
createdb -O greenplum psql

createdb -O greenplum arm
createdb -O greenplum postgres || true
createdb -O greenplum greenplum
./vm.sh
