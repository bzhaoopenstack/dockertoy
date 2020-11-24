useradd -m -d /home/greenplum -s /bin/bash greenplum && echo greenplum:greenplum | chpasswd && adduser greenplum sudo
echo "greenplum ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
su greenplum
cd 


export PGHOST=127.0.0.1
export PGVERSION=12
export TRAVIS_CPU_ARCH=arm64
export TRAVIS_PERL_VERSION=5.30

sudo apt-get -y --purge remove postgresql libpq-dev libpq5 postgresql-client-common postgresql-common
sudo rm -rf /var/lib/postgresql
#sudo apt-get -y --purge remove perl -y
if [[ $TRAVIS_CPU_ARCH =~ arm64* ]]; then
source /etc/lsb-release ;
echo "deb http://apt.postgresql.org/pub/repos/apt/ $DISTRIB_CODENAME-pgdg main ${PGVERSION}" > pgdg.list ;
sudo mv pgdg.list /etc/apt/sources.list.d/;
wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add - ;
fi
sudo apt-get update -qq
if [ $TRAVIS_CPU_ARCH =~ arm64* ] && [ $TRAVIS_PERL_VERSION =~ ^([0-9]+\.){1}([0-9]+)$ ]; then
    INSTALL_PERL_VERSION=$TRAVIS_PERL_VERSION.0 ;
    #curl -L https://install.perlbrew.pl | bash ;
	echo "yes" | sudo cpan App::perlbrew ;
	perlbrew init ;
    source ~/perl5/perlbrew/etc/bashrc ;
	cat ~/perl5/perlbrew/etc/bashrc >> ~/.bashrc ;
    perlbrew install -j 4 $INSTALL_PERL_VERSION -n ;
    perlbrew switch $INSTALL_PERL_VERSION ;
    perl --version ;
	echo "y" | perlbrew install-cpanm ;
	#target_dir=`which perl`
    #sudo rm -rf /usr/bin/cpanm /usr/bin/cpan /usr/bin/perl ;
    #sudo ln -s $target_dir /usr/bin/perl ;
    #sudo ln -s $(dirname $target_dir)/cpan /usr/bin/cpan ;
    #sudo wget http://xrl.us/cpanm -O /usr/bin/cpanm ;
    #sudo chmod +x /usr/bin/cpanm ;
    #cpanm -V ;
	#unset LANG ;
	#cpan install CGI ;
	#cpan install DBD::Pg ;
	#cpan install DBI ;
	#cpan install DBIx::Safe ;
    #cpanm DBIx::Safe CGI DBD::Pg DBI -n -f;
fi
sudo apt-get install -y \
    postgresql-${PGVERSION} \
    postgresql-client-${PGVERSION} \
    postgresql-${PGVERSION}-pgtap \
    postgresql-server-dev-${PGVERSION} \
    postgresql-server-dev-all \
    postgresql-plperl-${PGVERSION} \
    debhelper fakeroot libdbd-pg-perl \
    libtap-parser-sourcehandler-pgtap-perl
if [[ $TRAVIS_CPU_ARCH =~ arm64* ]]; then
    cpanm DBIx::Safe CGI DBD::Pg DBI -n -f;
fi
# Set PATH as postgresql-server-dev-all pretends version is 11
export PATH=/usr/lib/postgresql/${PGVERSION}/bin:${PATH}


which perl
ls -l `which perl`
perl -V
which cpan
ls -l `which cpan`
which cpanm
ls -l `which cpanm`
cpanm -V
git clone https://github.com/bzhaoopenstack/bucardo.git
cd bucardo
perl Makefile.PL
BUCARDO_LOG_ERROR_CONTEXT=1 PATH=$PATH:/usr/lib/postgresql/${PGVERSION}/bin make test


###POSTGRES_HOME

 
