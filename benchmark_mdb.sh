

TEST_VERSION=${$TEST_VERSION-"10.6.0"}



# init dir
cd /opt

mkdir test_mdb

cd test_mdb



# 下载社区版本
mkdir upstream

cd upstream

git clone https://github.com/MariaDB/server

cd ..



# 下载oe rpm包项目，安装所需依赖
mkdir src-openeuler

git clone https://gitee.com/src-openeuler/mariadb

cd mariadb

yum-builddep ./mariadb.spec -y

cd ..



# 进入源码包checkout分支并开始编译安装。
cd upstream
cd server
git checkout tags/$TEST_VERSION -b $TEST_VERSION
git submodule update --init --recursive
cd ..
mkdir cmake_build
cd cmake_build
cmake -DBUILD_CONFIG=mysql_release -DFEATURE_SET="community" -DCMAKE_INSTALL_PREFIX=/opt/projects/mysql/106/non-forked-mdb/mdb/installed/ ../server/

make -j7
make install
cd ../..



# 为MDB创建用户，安装路径，datadir, tmpdir
mkdir -p /opt/projects/mysql/106/non-forked-mdb/mdb/installed/
mkdir -p /data/mdb-data/node1/106/dn2
mkdir -p /data/mdb-data/node1/106/tmpdir2
adduser mysql -b /home/mysql
chown -R mysql:mysql /opt/projects/mysql/106/non-forked-mdb/mdb/installed/
chown -R mysql:mysql /data/mdb-data/node1/106/dn2
chown -R mysql:mysql /data/mdb-data/node1/106/tmpdir2



# MDB安装好后, 下载测试工具并编译安装
git clone https://github.com/mysqlonarm/benchmark-suites

git clone https://github.com/akopytov/sysbench.git
cd sysbench
yum install libtool -y
./autogen.sh
./configure --with-mysql-includes=/opt/projects/mysql/106/non-forked-mdb/mdb/installed/include/mysql/ --with-mysql-libs=/opt/projects/mysql/106/non-forked-mdb/mdb/installed/lib/ --prefix=/opt/test_mdb/sysbench-install
make -j7
make install
cd ..


# MDB和测试工具都安装完毕后，初始化MDB
/opt/projects/mysql/106/non-forked-mdb/mdb/installed/scripts/mysql_install_db --basedir=/opt/projects/mysql/106/non-forked-mdb/mdb/installed --datadir=/data/mdb-data/node1/106/dn2 --user=mysql

# 上面以mysql用户初始化，所以为了权限正确，需要切换到mysql用户来启动MDB
# adduser mysql -b /home/mysql
# su mysql
# Notes: 以下为mysql用户执行
/opt/projects/mysql/106/non-forked-mdb/mdb/installed//bin/mysqld_safe --defaults-file=/opt/test_mdb/benchmark-suites/mysql-sbench/conf/mdb.cnf/100tx1.5m_cpubound.cnf &
# 检查错误 /data/mdb-data/node1/106/dn1/host-192-168-0-144.err



# 初始化测试数据库database, 以下为socket连接"/tmp/n1.sock"为例
/opt/projects/mysql/106/non-forked-mdb/mdb/installed//bin/mysql --defaults-file=/opt/test_mdb/benchmark-suites/mysql-sbench/conf/mdb.cnf/100tx1.5m_cpubound.cnf -S /tmp/n1.sock < "create database arm;"
# /opt/projects/mysql/106/non-forked-mdb/mdb/installed//bin/mysql --defaults-file=/opt/test_mdb/benchmark-suites/mysql-sbench/conf/mdb.cnf/100tx1.5m_cpubound.cnf -u mysql -h127.0.0.1 -P4000 < "create database arm;"

# 进入工具目录，开始导入数据
/opt/test_mdb/sysbench-install/bin/sysbench --threads=24 --time=120 --rate=0 --report-interval=5 --db-driver=mysql --rand-type=uniform --mysql-host=localhost --mysql-port=4000 --mysql-socket=/tmp/n1.sock --mysql-db=arm --mysql$user=mysql --mysql-password= /opt/test_mdb/sysbench-install/share/sysbench//oltp_read_only.lua --tables=100 --table-size=1500000 prepare

# 所有工具准备完毕，开始测试
cd /opt/test_mdb
cd benchmark-suites
cd mysql-sbench

bash -x ./vm.sh | tee ~/log


