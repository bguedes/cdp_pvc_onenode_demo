#!/bin/bash
echo "> Installing required tools for CDP TRIAL"
if  [ -n "$(command -v yum)" ]; then
    echo ">> Detected yum-based Linux"
    sudo yum install -y util-linux
    sudo yum install -y lvm2
    sudo yum install -y e2fsprogs
    sudo yum install -y git
fi
if [ -n "$(command -v apt-get)" ]; then
    echo ">> Detected apt-based Linux"
    sudo apt-get update -y
    sudo apt-get install -y fdisk
    sudo apt-get install -y lvm2
    sudo apt-get install -y e2fsprogs
    sudo apt-get install -y git
fi

ROOT_DISK_DEVICE="/dev/sda"
echo "> Creating new partition for CDP"
sudo fdisk $ROOT_DISK_DEVICE <<EOF
d
n
p
1


w
EOF
sudo partprobe /dev/sda
sudo kpartx -u /dev/sda1
sudo e2fsck -f /dev/sda1
#sudo pvcreate /dev/sda1
sudo xfs_growfs /
cd /
sudo mkdir data

SECONDARY_DISK_DEVICE="/dev/sdb"
echo "> Creating new partition for DOCKER"
sudo fdisk $SECONDARY_DISK_DEVICE <<EOF
d
n
e
1


w
EOF

wipefs -a /dev/sdb

#Install the gui desktop collection of packages
yum groupinstall -y 'gnome desktop'
yum install -y 'xorg*'
yum remove -y initial-setup initial-setup-gui
systemctl isolate graphical.target
systemctl set-default graphical.target

#User Process Limit
ulimit -u 65536
#Open Files Limit
ulimit -n 1048576

#allow all traffic
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "Downloading github repo for one node cdp instance"

cd ~
git clone https://github.com/bguedes/cdp_pvc_onenode_demo
cd cdp_pvc_onenode_demo
chmod 777 setup.sh
sudo ./setup.sh $1 $2 $3

sudo reboot

exit 0
