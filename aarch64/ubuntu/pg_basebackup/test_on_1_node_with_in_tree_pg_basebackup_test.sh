
cd 
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
        wget net-tools vim
apt-get install zlib1g zlib1g-dev bzip2 libbz2-dev readline-common libreadline-dev bison libgmp-dev libmpfr-dev libmpc-dev -y
apt-get install flex -y
apt install ca-certificates -y
apt-get install libcurl4-openssl-dev libyaml-dev python-setuptools libpython-dev -y


useradd -m -d /home/pg -s /bin/bash pg && echo pg:pg | chpasswd && adduser pg sudo
echo "pg ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
su pg
cd


echo "yes" | sudo cpan App::perlbrew ;
perlbrew init ;
source ~/perl5/perlbrew/etc/bashrc ;
cat ~/perl5/perlbrew/etc/bashrc >> ~/.bashrc ;
perlbrew install-cpanm ;
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm IPC::Run -n
export LD_LIBRARY_PATH=$HOME/perl5/lib/perl5/
sudo apt install libperl-dev -y
cd
git clone https://github.com/postgres/postgres
cd postgres
./configure --prefix=$HOME/pgsql-install --enable-tap-tests --with-perl
make -j
make install


export PGDATA=$HOME/pgsql-install/data
export LD_LIBRARY_PATH=$HOME/pgsql-install/lib:$LD_LIBRARY_PATH
export PATH=$PATH:$HOME/pgsql-install/bin/
which psql
psql --version



#####
## ENV
#####
source ~/perl5/perlbrew/etc/bashrc ;
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
export LD_LIBRARY_PATH=$HOME/perl5/lib/perl5/
export PGDATA=$HOME/pgsql-install/data
export LD_LIBRARY_PATH=$HOME/pgsql-install/lib:$LD_LIBRARY_PATH
export PATH=$PATH:$HOME/pgsql-install/bin/
which psql
psql --version

cd src/bin/pg_basebackup/
make installcheck
