# cdp_pvc_onenode_demo
Fraud detection demo using CDP Private Cloud Base one node cluster installed using Vagrant


wget https://raw.githubusercontent.com/bguedes/cdp_pvc_onenode_demo/master/vagrant/VMSetup.sh
wget https://raw.githubusercontent.com/bguedes/cdp_pvc_onenode_demo/master/vagrant/Vagrantfile

Modify 

<change_me_for_username>
<change_me_for_password>

  config.vm.provision "shell", path: "VMSetup.sh", args: "<change_me_for_username> <change_me_for_password> templates/onenodecluster.json"
