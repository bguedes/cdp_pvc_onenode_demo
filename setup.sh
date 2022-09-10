#! /bin/bash

TEMPLATE=$3
USERNAME=$1
PASSWORD=$2

export FQDNx="$(hostname)" # There will be an annoying space added to the end. Next command will clear it with xargs
export FQDN=$(echo $FQDNx | xargs)

echo "-- Configure user cloudera with passwordless and pem file"
useradd cloudera -d /home/cloudera -p cloudera
sudo usermod -aG wheel cloudera
cp /etc/sudoers /etc/sudoers.bkp
rm -rf /etc/sudoers
sed '/^#includedir.*/a cloudera ALL=(ALL) NOPASSWD: ALL' /etc/sudoers.bkp > /etc/sudoers

echo "-- Configure and optimize the OS"
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local
# add tuned optimization https://www.cloudera.com/documentation/enterprise/6/6.2/topics/cdh_admin_performance.html
echo  "vm.swappiness = 1" >> /etc/sysctl.conf
sysctl vm.swappiness=1
timedatectl set-timezone UTC

echo "-- Install Java OpenJDK8 and other tools"
yum install -y java-1.8.0-openjdk-devel vim wget curl git bind-utils rng-tools
yum install -y epel-release
yum install -y python-pip

cp /usr/lib/systemd/system/rngd.service /etc/systemd/system/
systemctl daemon-reload
systemctl start rngd

echo "server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4" >> /etc/chrony.conf
systemctl restart chronyd

sudo /etc/init.d/network restart

echo "-- Configure networking"
sed -i$(date +%s).bak '/^[^#]*::1/s/^/# /' /etc/hosts
systemctl disable firewalld
systemctl stop firewalld
service firewalld stop
setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

echo  "Disabling IPv6"
echo "net.ipv6.conf.all.disable_ipv6 = 1
      net.ipv6.conf.default.disable_ipv6 = 1
      net.ipv6.conf.lo.disable_ipv6 = 1
      net.ipv6.conf.eth0.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

sudo systemctl restart network.service

echo "-- Install CM and MariaDB"

# CM 7
cat - >/etc/yum.repos.d/cloudera-manager.repo <<EOF
[cloudera-manager]
name=Cloudera Manager 7.7.1
baseurl=https://archive.cloudera.com/p/cm7/7.7.1/redhat7/yum/
gpgkey=https://archive.cloudera.com/p/cm7/7.7.1/redhat7/yum/RPM-GPG-KEY-cloudera
username=$USERNAME
password=$PASSWORD
gpgcheck=1
enabled=1
autorefresh=0
type=rpm-md

[postgresql10]
name=Postgresql 10
baseurl=https://archive.cloudera.com/postgresql10/redhat7/
gpgkey=https://archive.cloudera.com/postgresql10/redhat7/RPM-GPG-KEY-PGDG-10
enabled=1
gpgcheck=1
module_hotfixes=true
EOF

# MariaDB 10.1
cat - >/etc/yum.repos.d/MariaDB.repo <<EOF
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum clean all
rm -rf /var/cache/yum/
yum repolist

## CM
yum install -y cloudera-manager-agent cloudera-manager-daemons cloudera-manager-server

service cloudera-scm-agent restart

cd cdp_pvc_onenode_demo

## MariaDB
yum install -y MariaDB-server MariaDB-client
cat ./conf/mariadb.config > /etc/my.cnf

echo "--Enable and start MariaDB"
systemctl enable mariadb
systemctl start mariadb

echo "-- Install JDBC connector"
wget --progress=bar https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz -P ~
tar zxf ~/mysql-connector-java-5.1.46.tar.gz -C ~
mkdir -p /usr/share/java/
cp ~/mysql-connector-java-5.1.46/mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar
rm -rf ~/mysql-connector-java-5.1.46*

echo "-- Create DBs required by CM"
mysql -u root < ./scripts/create_db.sql

echo "-- Secure MariaDB"
mysql -u root < ./scripts/secure_mariadb.sql

echo "-- Prepare CM database 'scm'"
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm cloudera

## PostgreSQL see: https://www.postgresql.org/download/linux/redhat/
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install -y postgresql12
yum install -y postgresql12-server
pip install psycopg2==2.7.5 --ignore-installed

echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf
/usr/pgsql-12/bin/postgresql-12-setup initdb

cat ./conf/pg_hba.conf > /var/lib/pgsql/12/data/pg_hba.conf
cat ./conf/postgresql.conf > /var/lib/pgsql/12/data/postgresql.conf

echo "--Enable and start pgsql"
systemctl enable postgresql-12
systemctl start postgresql-12

echo "-- Create DBs required by CM"
sudo -u postgres psql <<EOF
CREATE DATABASE ranger;
CREATE USER ranger WITH PASSWORD 'cloudera';
GRANT ALL PRIVILEGES ON DATABASE ranger TO ranger;
CREATE DATABASE das;
CREATE USER das WITH PASSWORD 'cloudera';
GRANT ALL PRIVILEGES ON DATABASE das TO das;
CREATE ROLE ssb_admin LOGIN PASSWORD 'cloudera';
CREATE DATABASE ssb_admin OWNER ssb_admin ENCODING 'UTF8';
CREATE ROLE ssb_mve LOGIN PASSWORD 'cloudera';
CREATE DATABASE ssb_mve OWNER ssb_mve ENCODING 'UTF8';
EOF

echo "-- Install local parcels repo"
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/csa/1.7.0.0/parcels/FLINK-1.14.0-csa1.7.0.0-cdh7.1.7.0-551-26280481-el7.parcel -P /var/www/html/cloudera-repos/p/csa/1.7.0.0/parcels/
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/csa/1.7.0.0/parcels/FLINK-1.14.0-csa1.7.0.0-cdh7.1.7.0-551-26280481-el7.parcel.sha1 -P /var/www/html/cloudera-repos/p/csa/1.7.0.0/parcels/
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/csa/1.7.0.0/parcels/manifest.json -P /var/www/html/cloudera-repos/p/csa/1.7.0.0/parcels/

wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cfm2/2.1.4.0/redhat7/yum/tars/parcel/CFM-2.1.4.0-53-el7.parcel -P /var/www/html/cloudera-repos/p/cfm2/2.1.4.0/redhat7/yum/tars/parcel/
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cfm2/2.1.4.0/redhat7/yum/tars/parcel/CFM-2.1.4.0-53-el7.parcel.sha -P /var/www/html/cloudera-repos/p/cfm2/2.1.4.0/redhat7/yum/tars/parcel/
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cfm2/2.1.4.0/redhat7/yum/tars/parcel/manifest.json -P /var/www/html/cloudera-repos/p/cfm2/2.1.4.0/redhat7/yum/tars/parcel/

wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cdh7/7.1.7.1000/parcels/CDH-7.1.7-1.cdh7.1.7.p1000.24102687-el7.parcel -P /var/www/html/cloudera-repos/p/cdh7/7.1.7.1000/parcels
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cdh7/7.1.7.1000/parcels/CDH-7.1.7-1.cdh7.1.7.p1000.24102687-el7.parcel.sha1 -P /var/www/html/cloudera-repos/p/cdh7/7.1.7.1000/parcels
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cdh7/7.1.7.1000/parcels/manifest.json -P /var/www/html/cloudera-repos/p/cdh7/7.1.7.1000/parcels


wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cdsw1/1.10.0/parcels/CDSW-1.10.0.p1.19362179-el7.parcel -P /var/www/html/cloudera-repos/p/cdsw1/1.10.0/parcels
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cdsw1/1.10.0/parcels/CDSW-1.10.0.p1.19362179-el7.parcel.sha -P /var/www/html/cloudera-repos/p/cdsw1/1.10.0/parcels
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cdsw1/1.10.0/parcels/manifest.json -P /var/www/html/cloudera-repos/p/cdsw1/1.10.0/parcels

yum install httpd
systemctl start httpd

echo "-- Install CSDs for NIFI and NIFI REGISTRY"
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cfm2/2.1.4.0/redhat7/yum/tars/parcel/NIFI-1.16.0.2.1.4.0-53.jar -P /opt/cloudera/csd/
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cfm2/2.1.4.0/redhat7/yum/tars/parcel/NIFIREGISTRY-1.16.0.2.1.4.0-53.jar -P /opt/cloudera/csd/

echo "-- Install CSDs for Flink and SSB"
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/csa/1.7.0.0/csd/FLINK-1.14.0-csa1.7.0.0-cdh7.1.7.0-551-26280481.jar -P /opt/cloudera/csd/
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/csa/1.7.0.0/csd/SQL_STREAM_BUILDER-1.14.0-csa1.7.0.0-cdh7.1.7.0-551-26280481.jar -P /opt/cloudera/csd/

echo "-- Install CSDs for CDSW"
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cdsw1/1.10.0/csd/CLOUDERA_DATA_SCIENCE_WORKBENCH-CDPDC-1.10.0.jar	 -P /opt/cloudera/csd/
wget --progress=bar:force https://$USERNAME:$PASSWORD@archive.cloudera.com/p/cdsw1/1.10.0/csd/CLOUDERA_DATA_SCIENCE_WORKBENCH-CDH6-1.10.0.jar -P /opt/cloudera/csd/

chown cloudera-scm:cloudera-scm /opt/cloudera/csd/*
chmod 644 /opt/cloudera/csd/*

wget --progress=bar:force https://jdbc.postgresql.org/download/postgresql-42.2.23.jar --no-check-certificate
mv postgresql-42.2.23.jar postgresql-connector-java.jar
cp postgresql-connector-java.jar /usr/share/java
pip install psycopg2-binary==2.8.5 -t /usr/share/python3

echo "-- Enable passwordless root login via rsa key"
ssh-keygen -f ~/myRSAkey -t rsa -N ""
mkdir ~/.ssh
cat ~/myRSAkey.pub >> ~/.ssh/authorized_keys
chmod 400 ~/.ssh/authorized_keys
ssh-keyscan -H `hostname` >> ~/.ssh/known_hosts
sed -i 's/.*PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config
systemctl restart sshd

echo "-- Start CM, it takes about 2 minutes to be ready"
systemctl start cloudera-scm-server

while [ `curl -s -X GET -u "admin:admin"  http://localhost:7180/api/version` -z ] ;
    do
    echo "waiting 10s for CM to come up..";
    sleep 10;
done

chmod -R 777 /opt/cloudera/parcel-repo
chmod -R 777 /opt/cloudera/parcel-cache
chmod -R 777 /opt/cloudera/csd
chmod -R 777 /opt/cloudera/parcels

#for issue File "./scripts/create_cluster.py", line 2, in <module>
rm -rfv /usr/lib/python2.7/site-packages/certifi/*
pip install certifi==2020.4.5.1

echo "-- Now CM is started and the next step is to automate using the CM API"
pip install cm_client

sed -i "s/YourHostname/${FQDN}/g" ./scripts/create_cluster.py
sed -i "s/YourHostname/${FQDN}/g" $TEMPLATE
sed -i "s/YourCDSWDomain/${FQDN}/g" $TEMPLATE

#sed -i "s/YourHostname/localhost.localdomain/g" ./scripts/create_cluster.py
#sed -i "s/YourHostname/localhost.localdomain/g" $TEMPLATE

mkdir /data/dfs
chmod -R 777 /data

python ./scripts/create_cluster.py $TEMPLATE

sudo usermod cloudera -G hadoop
sudo -u hdfs hdfs dfs -mkdir /user/cloudera
sudo -u hdfs hdfs dfs -chown cloudera:hadoop /user/cloudera
sudo -u hdfs hdfs dfs -mkdir /user/admin
sudo -u hdfs hdfs dfs -chown admin:hadoop /user/admin
sudo -u hdfs hdfs dfs -chmod -R 0755 /tmp
