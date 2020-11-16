# Base repo load
apt install vim -y
curl https://repogen.simplylinux.ch/txt/xenial/sources_dce40f508e412c2a0ea584c2150c0fd3111c0b6b.txt| tee /etc/apt/sources.list
apt update
wget -O /etc/apt/sources.list https://repo.huaweicloud.com/repository/conf/Ubuntu-Ports-xenial.list


# Config the dib env
cd /opt/
apt update
apt install -y debootstrap gdisk dosfstools git
git clone https://github.com/openstack/diskimage-builder.git
apt install python3 python3-dev python3-pip -y
export DIB_RELEASE=bionic
export DIB_CHECKSUM=1
export DIB_SHOW_IMAGE_USAGE=1
export DIB_APT_LOCAL_CACHE=0
export DIB_DISABLE_APT_CLEANUP=1
mkdir -p /root/zuul-key/id_rsa.pub
rm -rf /root/zuul-key/id_rsa.pub
vi /root/zuul-key/id_rsa.pub
chmod 600 /root/zuul-key/id_rsa.pub
export DIB_DEV_USER_USERNAME=zuul
export DIB_DEV_USER_PWDLESS_SUDO=yes
export DIB_DEBIAN_COMPONENTS='main,universe'

# install dib
cd diskimage-builder/
pip3 install -r requirements.txt ; pip3 install -r test-requirements.txt ; python3 setup.py install
cd /opt/


# install vhd-util from apt repo but might failed
apt-get install -y blktap-utils squashfs-tools kpartx qemu-utils
which vhd-util


# Download the vhd-util repo and apply the deps patch.
cd /opt/
git clone https://github.com/emonty/vhd-util.git
cd vhd-util
git apply debian/patches/citrix
git status
git add .
git status
git commit -m "concert"
git log -2


# install xen
apt-get -q install -y --no-install-recommends build-essential ccache libevent-dev libapr1-dev libffi-dev libssl-dev git python-pip python-dev gcc libsodium-dev libcurl4-openssl-dev libzstd1-dev libldap2-dev flex libbz2-dev bison libpq-dev postgresql-server-dev-all postgresql-common libyaml-dev zlib1g zlib1g-dev sudo vim net-tools less iputils-ping iproute2 ssh locales locales-all wget
cd /opt/
git clone git://xenbits.xen.org/xen.git
cd xen/
apt-get install -y texinfo gettext iasl
apt-get install libtool lib32ncurses5-dev -y
apt-get install libtool libncurses5-dev -y
apt-get install -y pkg-config
apt install libglib2.0-dev -y
apt install libyajl-dev libpixman-1.dev -y
apt install libfdt -y
apt install libfdt-dev -y
./configure
make world
make install
which xen

# install vhd-util fixed binary
cd /opt/
cd vhd-util/
apt install libaio1  -y
apt install libaio-dev  -y
./configure --prefix=/opt/vhd-install/ --host=arm --build=arm --target=arm
make
make install
bash -x ./install.sh
which vhd-utls
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt//vhd-install/lib
../vhd-install/sbin/vhd-util --help
export PATH=$PATH:/opt//vhd-install/bin:/opt//vhd-install/sbin
vhd-util --help

# Build image
cd /opt/
disk-image-create -a arm64 -o ubuntu-bionic-arm64.vhd -t vhd -x -u ubuntu vm simple-init growroot devuser openssh-server

