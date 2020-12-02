# ROOT USER SETTINGS
apt-get -q update
apt-get -q install -y --no-install-recommends build-essential autoconf automake libtool cmake zlib1g-dev pkg-config libssl-dev libssl1.0.0 libsasl2-dev bats curl sudo git wget net-tools vim
useradd -m -d /home/pgbackrest -s /bin/bash pgbackrest && echo pgbackrest:pgbackrest | chpasswd && adduser pgbackrest sudo
echo "pgbackrest ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


# NORMAL USER SETTINGS
cd
echo "yes" | sudo cpan App::perlbrew
perlbrew init
source ~/perl5/perlbrew/etc/bashrc
cat ~/perl5/perlbrew/etc/bashrc >> ~/.bashrc
perlbrew install-cpanm
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm YAML/XS.pm XML::Parser XML/Checker/Parser.pm XML::Parser::PerlSAX -n

sudo apt install expat -y

git clone https://github.com/pgbackrest/pgbackrest ; cd pgbackrest


export PGB_CI_TEST1="test --vm=none --param=no-coverage --param=module=command --param=module=storage"

export PGB_CI_TEST2="test --vm=none"

cd ~

# will mount a default test volume on local_dir/test directory.
# The test might be fail when execution, so you need to remove the orphan resources
# Such as:
#   1. the mounted volume in local_dir/test
#   2. You need to touch a sudo file in /etc/sudoers.d/travis
# sudo umount /home/pgbackrest/test
# sudo touch /etc/sudoers.d/travis

sudo touch /etc/sudoers.d/travis
${BUILD_DIR?}/test/travis.pl ${PGB_CI_TEST1?}

df -h

sudo touch /etc/sudoers.d/travis
${BUILD_DIR?}/test/travis.pl ${PGB_CI_TEST2?}
