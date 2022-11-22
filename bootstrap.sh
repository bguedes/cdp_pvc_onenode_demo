#!/bin/bash

vagrant plugin install vagrant-vbguest

export VAGRANT_EXPERIMENTAL="disks"
vagrant plugin install vagrant-disksize

vagrant plugin install vagrant-hostmanager

wget https://raw.githubusercontent.com/bguedes/cdp_pvc_onenode_demo/main/vagrant/VMSetup.sh
wget https://raw.githubusercontent.com/bguedes/cdp_pvc_onenode_demo/main/vagrant/Vagrantfile
