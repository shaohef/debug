# veth debug

This is veth debug utility. It will help another veth peer in another namespace.
It is useful for siniffer in calico BGP and ovs veth interface network topology.

## install

Centos

   ```
   yum -y install gcc
   yum install python3-devel
   yum install util-linux
   ```
Ubuntu

   ``` 
   apt-get install python3-dev
   ```

install python package with proxy

   ```
   PROXY=http://proxy-mu.intel.com:911
   pip3 --proxy $PROXY install psutil
   pip3 --proxy $PROXY install pyroute2
   pip3 --proxy $PROXY install nsenter   # NOTE: this version is too low
   ```
install python package without proxy

   ```
   pip3 install psutil
   pip3 install pyroute2
   pip3 install nsenter   # NOTE: this version is too low
   ```

move older version nsenter
   ```
   mv /usr/local/bin/nsenter /usr/local/bin/nsenter_pip
   ln -s /usr/bin/nsenter /usr/local/bin/nsenter
   ```
## usage

get calico interface by

   ```
   ip a | grep calic
   ip r | grep calic
   ```

get ovs interface by

   ```
   ovs-vsctl list-br
   ovs-vsctl list-ports br-int
   ```

export the utils function
   ```
   source debug/veth/utils.sh 
   ```

probe the type of interface

   ```
   DEV=cali8f43c28540a
   devtype $DEV
   ```

get veth interface peer info

   ```

   DEV=cali8f43c28540a

   nsdev2peer $DEV
   dev2ipnet $DEV
   dev2peerpid $DEV
   dev2peercname $DEV
   dev2peerip $DEV
   ```
