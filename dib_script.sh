apt-get install -y debootstrap gdisk dosfstools
export DIB_RELEASE=bionic
export DIB_CHECKSUM=1
export DIB_SHOW_IMAGE_USAGE=1
export DIB_APT_LOCAL_CACHE=0
export DIB_DISABLE_APT_CLEANUP=1
export DIB_DEV_USER_AUTHORIZED_KEYS=/root/zuul-key/id_rsa.pub
export DIB_DEV_USER_USERNAME=zuul
export DIB_DEV_USER_PWDLESS_SUDO=yes
export DIB_DEBIAN_COMPONENTS='main,universe'
disk-image-create -x -t qcow2 -a arm64 -o /tmp/ubuntu-bionic-aarch64 ubuntu vm simple-init block-device-efi growroot devuser openssh-server zuul-worker infra-package-needs pip-and-virtualenv
