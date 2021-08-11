
##### 1. 初始化系统盘
# 初始化instance扩大系统盘
# https://support.huaweicloud.com/usermanual-evs/evs_01_0072.html

yum install cloud-utils-growpart -y

# 绑在/目录的硬盘为/dev/vda2
growpart /dev/vda 2

# 扩展磁盘分区文件系统的大小
resize2fs /dev/vda2
df -TH


### yum update后如果软件仓库有内核更新，需要reboot重启才会生效。


##### 2.构造目录结构
cd /opt/
mkdir kernels
cd kernels
mkdir upstream
cd upstream
git clone https://gitee.com/openeuler/kernel
cd ..

mkdir src-openeuler
cd src-openeuler
git clone https://gitee.com/src-openeuler/kernel
yum install rpm-build
cd kernel
yum-builddep ./kernel.spec -y
cd ..


##### 3.下载和编译内核
mkdir release_pkg
# 查看当前uname -a的kernel version, 然后下载对应的release tar.gz包，准备开始编译和替换
# https://blog.csdn.net/m0_56602092/article/details/118604262
uname -a

# 下载对应版本release.tar.gz
yum install wget -y
wget https://github.com/openeuler-mirror/kernel/archive/4.19.90-2107.5.0.tar.gz

tar -zxvf 4.19.90-2107.5.0.tar.gz

cd kernel-4.19.90-2107.5.0

# 清理过去内核编译产生的文件，第一次编译时可不执行此命令
make mrproper

# 先将将系统原配置文件拷贝过来，原配置文件在/boot目录下，输入config-后tab一下就出来了
cp -v /boot/config-$(uname -r) .config

# 然后使用make menuconfig 对配置进行需要的更改，决定将内核的各个功能系统编译进内核还是编译为模块还是不编译
make menuconfig
# 进入图形界面更改kernel配置
# 例如 getconf PAGESIZE 在未替换内核前为64K。
# 然后打开.config文件确认
# CONFIG_ARM64_4K_PAGES=y

# 配置完成，开始编译和安装
yum install elfutils-libelf-devel openssl-devel -y

# make -j
make

# 安装模块及替换
make modules_install

# 安装
make install

# /boot目录下查看新安装的内核

# 更新引导
grub2-mkconfig -o /boot/grub2/grub.cfg

# 重启机器，查看kernel版本是否正确。


