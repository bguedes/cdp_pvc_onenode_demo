# cdp_pvc_onenode_demo

Fraud detection demo using CDP Private Cloud Base one node cluster installed using Vagrant

This github repository will show you how to install a CDP Private Cloud Base using Cloudera Manager in a virtualized environment using VirtualBox managed by Vagrant

### Requirements

Your laptop needs at minimum 32GB RAM and at least 100GB disk space. <br />
An Internet connection is also required, as this installation process will download various files required to perform the automated installation.<br />

Please install :

-[Linux Mint 20.3](https://linuxmint.com/download.php)\
-[VirtualBox 6.1](https://www.virtualbox.org/)\
-[Vagrant 2.2.16](https://www.vagrantup.com/)
  
This project has been tested with on a Laptop Intel Core i7 with 16 cores and with 32GB of memory<p>  

### Usage
  
Please execute those following command lines :

```
wget https://raw.githubusercontent.com/bguedes/bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh

```
  
Modify on the downloaded Vagrantfile

<change_me_for_username>
<change_me_for_password>
  
Apply the username and password given for your Cloudera CDP PvC licence.

```
  config.vm.provision "shell", path: "VMSetup.sh", args: "<change_me_for_username> <change_me_for_password> templates/onenodecluster.json"
```

After that execute :  
  
``` 
  vagrant up
```  
  
### Power off the VM  
  
``` 
  vagrant halt
```    

### Boot the VM  
  
``` 
  vagrant reload
```    
