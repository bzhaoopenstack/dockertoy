apt-get install -y debootstrap gdisk dosfstools
apt-get install python3 python3-pip python3-setuptools
pip3 install -U pip setuptools

mkdir -p /root/zuul-key/
cat <<EOF > /root/zuul-key/id_rsa.pub
ssh-rsa NEED_EXCHANGE USER@HOST
EOF

chwon 600 /root/zuul-key/id_rsa.pub
useradd -m -d /home/nodepool -s /bin/bash nodepool && echo nodepool:nodepool | chpasswd && adduser nodepool sudo
echo "nodepool ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chown nodepool:nodepool /root/zuul-key/id_rsa.pub

git clone https://git.openstack.org/openstack/diskimage-builder
git clone https://git.openstack.org/openstack/dib-utils
git clone https://opendev.org/openstack/project-config

cp -rf project-config/nodepool/elements/* diskimage-builder/diskimage_builder/elements/

cd diskimage-builder/
pip3 install .
cd -
export PATH=$PATH:$(pwd)/diskimage-builder/bin:$(pwd)/dib-utils/bin

export DIB_DISABLE_APT_CLEANUP=0
export DIB_CHECKSUM=1
export DIB_DEV_USER_PWDLESS_SUDO=1
export DIB_APT_LOCAL_CACHE=0
export TMP_BUILD_DIR=/opt/wkdir/
export DIB_DEBIAN_COMPONENTS=main,universe
export OS_CLOUD=linaro
export DIB_DEV_USER_AUTHORIZED_KEYS=/root/zuul-key/id_rsa.pub
export TMPDIR=/opt/dib_tmp
export DIB_RELEASE=xenial
export ELEMENTS_PATH=/root/diskimage-builder/diskimage_builder/elements
export DIB_IMAGE_CACHE=/opt/cache
export DIB_DEBOOTSTRAP_EXTRA_ARGS=--no-check-gpg
export DIB_IMAGE_SIZE=80
export DIB_DEV_USER_USERNAME=zuul
export DIB_SHOW_IMAGE_USAGE=1
export GIT_HTTP_LOW_SPEED_TIME=300

# Remove cache-devstack element
DISKIMAGE_EXEC=`which disk-image-create`
$DISKIMAGE_EXEC -x --no-tmpfs -t qcow2 -a arm64 -o /root/ubuntu-xenial-aarch64 ubuntu-minimal vm simple-init block-device-efi nodepool-base initialize-urandom growroot devuser openssh-server zuul-worker infra-package-needs pip-and-virtualenv


# pip3 install python-openstackclient --ignore-installed PyYAML
pip3 install python-openstackclient

mkdir -p /etc/openstack/
cat <<EOF > /etc/openstack/clouds.yaml
clouds:
  linaro:
    auth:
      auth_url: XXXXXXXXXX
      password: XXXXXXXXXX
      project_domain_name: XXXXXXXXXX
      project_domain_id: XXXXXXXXXX
      project_name: XXXXXXXXXX
      user_domain_name: XXXXXXXXXX
      username: XXXXXXXXXX
    identity_api_version: '3'
    network_api_version: '2.0'
    region_name: XXXXXXXXXX
    volume_api_version: '2'
EOF

export OS_CLOUD=linaro
openstack image create ubuntu-xenial-arm64 --disk-format qcow2 --file /root/ubuntu-xenial-aarch64.qcow2 --private
