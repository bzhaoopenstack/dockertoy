#HOST1 HOST2 INFO
#==========================
# HOST1: 172.17.0.4    pg1
# HOST2: 172.17.0.3    pg2


#HOST1
#==========================
useradd -m -d /home/pg1 -s /bin/bash pg1 && echo pg1:pg1 | chpasswd && adduser pg1 sudo
echo "pg1 ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
su pg1
cd 


#HOST2
#==========================
useradd -m -d /home/pg2 -s /bin/bash pg2 && echo pg2:pg2 | chpasswd && adduser pg2 sudo
echo "pg2 ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
su pg2
cd 

#HOST1 && HOST2
#==========================
cd 
sudo apt-get -q update \
    && sudo apt-get -q install -y --no-install-recommends \
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
		net-tools \
		vim
sudo apt-get install zlib1g zlib1g-dev bzip2 libbz2-dev readline-common libreadline-dev bison libgmp-dev libmpfr-dev libmpc-dev -y
sudo apt-get install flex -y
sudo apt install ca-certificates -y
sudo apt-get install libcurl4-openssl-dev libyaml-dev python-setuptools libpython-dev -y
cd
git clone https://github.com/postgres/postgres
cd postgres
./configure --prefix=$HOME/pgsql-install
make && make install

export PGDATA=$HOME/pgsql-install/data
export LD_LIBRARY_PATH=$HOME/pgsql-install/lib
export PATH=$PATH:$HOME/pgsql-install/bin/
which psql
psql --version

#HOST1
==============================
# if remove the postgresql.conf in case, we can first to remove the pgdata directory and rerun initdb below.
initdb --pgdata=$PGDATA --encoding=UTF8

cat <<EOF >> $PGDATA/postgresql.conf
#checkpoint_segments = 10
max_wal_senders = 3 
#wal_keep_segments = 10
wal_level = archive   
logging_collector = on
listen_addresses = '*' 
log_line_prefix = '%m [%p-%l] %q%u@%d '
synchronous_standby_names = '*'
max_replication_slots = 5 
EOF

cat <<EOF >> $PGDATA/pg_hba.conf
host    all             all         172.17.0.3/32            trust
host    replication     pg1         172.17.0.3/32            trust
#host   type            host1's user   host2's IP/32            trust
EOF

pg_ctl -D $PGDATA -l $PGDATA/postgres.log start -o "-p 19000"

ps -axf | grep postgres


gsql -U$DB_USER -W$DB_PASSWORD -h $DB_HOST -p$DB_PORT -d postgres -c "DROP TABLE IF EXISTS ${table_name}; ${sql%?}); \COPY ${table_name} from ${DATA_DIR}${file} delimiter ',' csv header;"
psql -Upg1 -p19000 -d postgres -c "SELECT * FROM pg_create_physical_replication_slot('node_a_slot');"
psql -Upg1 -p19000 -d postgres -c "SELECT * FROM pg_replication_slots;"


#HOST2
==============================
# pg_basebackup -D $PGDATA -Fp -Xs -v -P -h HOST1IP -p 19000 -U HOST1_PGUSER
pg_basebackup -D $PGDATA -Fp -Xs -v -P -h 172.17.0.4 -p 19000 -U pg1


cat <<EOF >> $PGDATA/pg_hba.conf
host    all             all         172.17.0.4/32            trust
host    replication     pg2         172.17.0.4/32            trust
#host   type            host2's user   host1's IP/32            trust
EOF


cat <<EOF >> $PGDATA/postgresql.conf
#checkpoint_segments = 10
max_wal_senders = 3 
#wal_keep_segments = 10
EOF

sed -i -e 's/wal_level = archive/wal_level = hot_standby/g' $PGDATA/postgresql.conf

# recovery.conf
cat <<EOF >> $PGDATA/postgresql.conf
#standby_mode = on
hot_standby = on 
primary_conninfo = 'host=172.17.0.4 port=19000 user=pg1'
# host=host1's IP port=host1's port user=host1's user
primary_slot_name = 'node_a_slot'
promote_trigger_file = '~/postgresql.trigger.19000'
EOF

#HOST1
==============================
pg_ctl stop -D $PGDATA -m immediate



#HOST1 && HOST2
==============================
# startup master and slave services
pg_ctl -D $PGDATA -l $PGDATA/postgres.log start -o "-p 19000"


pg_ctl -D $PGDATA -l $PGDATA/postgres.log start -o "-p 19000"


#HOST2
==============================
ps -axf | grep postgres





CREATE TABLE test (id integer, test integer) WITH (OIDS=FALSE);
ALTER TABLE test OWNER TO pg1;

psql -Upg1 -p5432 -d postgre -c "CREATE TABLE test (id integer, test integer) WITH (OIDS=FALSE);ALTER TABLE test OWNER TO pg1;insert into test SELECT generate_series(1,1000000) as key, (random()*(10^3))::integer;"
