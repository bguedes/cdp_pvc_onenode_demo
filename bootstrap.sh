#!/bin/bash

vagrant plugin install vagrant-vbguest

$VAGRANT_EXPERIMENTAL="disks"
vagrant plugin install vagrant-disksize
