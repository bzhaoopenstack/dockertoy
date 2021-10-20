# summary
# ENV: 3 Nodes
# master: gpdb01
# segments_hosts : gpdb02, gpdb03

git clone https://gitee.com/src-openeuler/gpdb

arr=(rpm-build yum-utils python2-devel python2-pip apr-devel bison bzip2-devel cmake3 flex gcc gcc-c++ krb5-devel libcurl-devel libevent-devel libkadm5 libyaml-devel libxml2-devel libzstd-devel openssl-devel perl-ExtUtils-Embed readline-devel xerces-c-devel zlib-devel apr apr-util bash bzip2 curl iproute krb5-devel less libcurl libxml2 libyaml net-tools openldap openssh openssh-clients openssh-server openssl perl readline rsync sed tar which zip zlib hostname net-tools iputils libzstd-devel apr-devel libevent-devel libxml2-devel libcurl-devel bzip2-devel)

for var in ${arr[@]};
do
	yum install $var -y
done

ln -s /usr/bin/python2 /usr/bin/python

cd gpdb
git checkout remotes/origin/openEuler-20.03-LTS-Next -b next

tar -zxvf 6.17.0-src-full.tar.gz

cd gpdb_src/

patch -p1 < ../orca1.patch ; patch -p1 < ../orca2.patch ; patch -p1 < ../unittest-fix.patch ; patch -p1 < ../gpfdist1.patch ; patch -p1 < ../gpfdist2.patch ; patch -p1 < ../icw.patch

./configure --enable-orca --with-gssapi --disable-rpath --prefix=$PWD/greenplum-db-6.7.0  --with-libxml --with-openssl --enable-cassert --enable-debug  --enable-debug-extensions  --disable-mapreduce  --enable-orafce  --without-perl  --with-python
make -j15 install

# 还必须是私网IP，后续生成pg_hba.conf全是私网IP，用公网IP不生效
cat << EOF >> /etc/hosts
192.168.1.14 gpdb01
192.168.1.234 gpdb02
192.168.1.200 gpdb03


#159.138.59.78 gpdb01
#119.8.124.255 gpdb02
#159.138.57.139 gpdb03

EOF

# 内核配置
cat << EOF > /etc/sysctl.conf
kernel.shmall = 4000000000
kernel.shmmax = 500000000
kernel.shmmni = 4096
vm.overcommit_memory = 2 
vm.overcommit_ratio = 95 
net.ipv4.ip_local_port_range = 10000 65535 
kernel.sem = 500 2048000 200 40960
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.msgmni = 2048
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.arp_filter = 1
net.core.netdev_max_backlog = 10000
net.core.rmem_max = 2097152
net.core.wmem_max = 2097152
vm.swappiness = 10
vm.zone_reclaim_mode = 0
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.dirty_background_ratio = 0 
vm.dirty_ratio = 0
vm.dirty_background_bytes = 1610612736
vm.dirty_bytes = 4294967296
EOF

sysctl -p



cat << EOF >> /etc/security/limits.conf
* soft nofile 524288
* hard nofile 524288
* soft nproc 131072
* hard nproc 131072
EOF


groupdel gpadmin
userdel gpadmin


groupadd -g 530 gpadmin
useradd -g 530 -u 530 -m -d /home/gpadmin -s /bin/bash gpadmin

chown -R gpadmin:gpadmin /home/gpadmin/
passwd gpadmin


mkdir /usr/local/greenplum
chown -R gpadmin:gpadmin /usr/local/greenplum/

cp -rf  ./greenplum-db-6.7.0/* /usr/local/greenplum/
chown -R gpadmin:gpadmin /usr/local/greenplum/*


su gpadmin
ssh-keygen -t rsa

ssh-copy-id gpdb01
ssh-copy-id gpdb02
ssh-copy-id gpdb03


mkdir /home/gpadmin/conf
cd /home/gpadmin/conf
touch hostlist
touch seg_hosts

cat << EOF > hostlist
gpdb01
gpdb02
gpdb03
EOF

cat << EOF > seg_hosts
gpdb02
gpdb03
EOF


source /usr/local/greenplum/greenplum_path.sh
# master
cd /home/gpadmin/conf/
gpssh-exkeys -f hostlist

# gpssh -f hostlist
mkdir -p /home/gpadmin/data/master
# - master


# segments hosts
source /usr/local/greenplum/greenplum_path.sh 
gpssh -f /home/gpadmin/conf/seg_hosts -e 'mkdir -p /home/gpadmin/data/primary'
gpssh -f /home/gpadmin/conf/seg_hosts -e 'mkdir -p /home/gpadmin/data/mirror'

# - segments hosts

# master, 必须在.bashrc 和 .bash_profile同时生效
cat << EOF > /home/gpadmin/.bash_profile
source /usr/local/greenplum/greenplum_path.sh
export MASTER_DATA_DIRECTORY=/home/gpadmin/data/master/gpseg-1
export PGPORT=5432
export PGUSER=gpadmin
EOF

source /home/gpadmin/.bash_profile

cat << EOF >> /home/gpadmin/.bashrc
source /usr/local/greenplum/greenplum_path.sh
export MASTER_DATA_DIRECTORY=/home/gpadmin/data/master/gpseg-1
export PGPORT=5432
export PGUSER=gpadmin
EOF

source /home/gpadmin/.bashrc
# - master

# segments 与下方gpconf对应, 必须在.bashrc 和 .bash_profile同时生效
cat << EOF > /home/gpadmin/.bash_profile
source /usr/local/greenplum/greenplum_path.sh
export MASTER_DATA_DIRECTORY=/home/gpadmin/data/master/gpseg-1
export PGPORT=33000
export PGUSER=gpadmin
EOF

source /home/gpadmin/.bash_profile

cat << EOF >> /home/gpadmin/.bashrc
source /usr/local/greenplum/greenplum_path.sh
export MASTER_DATA_DIRECTORY=/home/gpadmin/data/master/gpseg-1
export PGPORT=33000
export PGUSER=gpadmin
EOF

source /home/gpadmin/.bashrc
# - segments

mkdir /home/gpadmin/gpconfigs
cp $GPHOME/docs/cli_help/gpconfigs/gpinitsystem_config /home/gpadmin/gpconfigs/gpinitsystem_config

cat << EOF > /home/gpadmin/gpconfigs/gpinitsystem_config
#数据库代号
ARRAY_NAME="Greenplum"

#segment前缀
SEG_PREFIX=gpseg

#primary segment 起始的端口号
PORT_BASE=33000

#指定primary segment的数据目录,网上写的是多个相同目录，多个目录表示一台机器有多个segment
declare -a DATA_DIRECTORY=(/home/gpadmin/data/primary)

#master所在机器的host name
MASTER_HOSTNAME=gpdb01

#master的数据目录
MASTER_DIRECTORY=/home/gpadmin/data/master

#master的端口
MASTER_PORT=5432

#指定bash的版本
TRUSTED_SHELL=/usr/bin/ssh

#将日志写入磁盘的间隔，每个段文件通常 =16MB < 2 * CHECK_POINT_SEGMENTS + 1
CHECK_POINT_SEGMENTS=8

#字符集
ENCODING=UNICODE

#mirror segment 起始的端口号
MIRROR_PORT_BASE=44000

# mirror的数据目录，和主数据一样，一个对一个，多个对多个
declare -a MIRROR_DATA_DIRECTORY=(/home/gpadmin/data/mirror)
EOF

cp /home/gpadmin/conf/seg_hosts /home/gpadmin/gpconfigs/hostfile_gpinitsystem



# master上初始化gpdb
cd ~
gpinitsystem -c gpconfigs/gpinitsystem_config -h gpconfigs/hostfile_gpinitsystem

# 验证
psql -d postgres
#psql (9.4.24)
#Type "help" for help.
#
#postgres=# select version();
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------
# PostgreSQL 9.4.24 (Greenplum Database 6.17.0 build commit:9b887d27cef94c03ce3a3e63e4f6eefb9204631b) on aarch64-unknown-linux-gnu, compiled by gcc (GCC) 8.4.1 20200928 (Red Hat 8.4.1-1), 64-bit #compiled on Oct 19 2021 16:09:13 (with a
#ssert checking)
#(1 row)

# - master
