# Build one CDP Base node VM using Vagrant

This repository will show you how to build a one node CDP Base cluster in a virtualized environment using VirtualBox managed by Vagrant.

After getting your CDP Base instance created, this document will describe how to add CDSW.

### Requirements

Your desktop/laptop needs at minimum 32GB RAM and at least 400GB disk space. <br />
An Internet connection is also required, as this installation process will download various files required to perform the automated installation.<br />

Please install :

-[VirtualBox](https://www.virtualbox.org/)\
-[Vagrant](https://www.vagrantup.com/)
  
This project has been tested with on a Laptop Intel Core i7 with 16 cores and with 32GB of memory<p>  

### Usage
  
Please execute those following command lines :

#### Linux 
  
```
wget https://raw.githubusercontent.com/bguedes/cdp_pvc_onenode_demo/main/bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh

```
#### Windows Powershell 
  
```
Invoke-WebRequest -Uri https://raw.githubusercontent.com/bguedes/cdp_pvc_onenode_demo/main/windows_bootstrap.sh -UseBasicParsing -OutFile bootstrap.sh
./bootstrap.sh

``` 
  
#### License Credentials  
  
Modify on the downloaded Vagrantfile

<change_me_for_username><br>
<change_me_for_password>
  
Apply the username and password given for your Cloudera CDP PvC licence.

```
  config.vm.provision "shell", path: "VMSetup.sh", args: "<change_me_for_username> <change_me_for_password> templates/onenodecluster.json"
```

#### Launch CDP VM installation

Use Vagrant executing this command :  
  
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
