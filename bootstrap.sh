#!/bin/bash

vagrant plugin install vagrant-vbguest

$VAGRANT_EXPERIMENTAL="disks"
vagrant plugin install vagrant-disksize

vagrant plugin install vagrant-hostmanager

cd
mkdir cdpvm
cd cdpvm

wget https://raw.githubusercontent.com/bguedes/cdp_pvc_onenode_demo/master/vagrant/VMSetup.sh
wget https://raw.githubusercontent.com/bguedes/cdp_pvc_onenode_demo/master/vagrant/Vagrantfile
