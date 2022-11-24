#!/bin/bash

vagrant plugin install vagrant-vbguest

export VAGRANT_EXPERIMENTAL="disks"
vagrant plugin install vagrant-disksize

vagrant plugin install vagrant-hostmanager

vagrant plugin install vagrant-scp

Invoke-WebRequest -Uri https://raw.githubusercontent.com/bguedes/cdp_pvc_onenode_demo/main/vagrant/VMSetup.sh -UseBasicParsing -OutFile VMSetup.sh
Invoke-WebRequest -Uri https://raw.githubusercontent.com/bguedes/cdp_pvc_onenode_demo/main/vagrant/Vagrantfile -UseBasicParsing -OutFile Vagrantfile

Invoke-WebRequest -Uri https://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-2004_01.VirtualBox.box -UseBasicParsing -OutFile CentOS-7-x86_64-Vagrant-2004_01.VirtualBox.box

vagrant box add CentOS-7-x86_64-Vagrant-2004_01.VirtualBox.box --name centos7
