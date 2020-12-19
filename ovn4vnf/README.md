# veth debug

This is veth debug utility. It will use ovs-tcpdump as sinffer for ovs interface

## install

   ```
   NFNA=`kubectl get pod -A -o name |grep ovn-controller`
   NM=kube-system
   H_PROXY=http://proxy-mu.intel.com:911


   # kubectl -n $NM exec -it ${NFNA} -- bash -c "echo $'nameserver 10.248.2.1\nnameserver 163.33.253.68\nnameserver 10.216.46.196' >> /etc/resolv.conf" H_PROXY=http://proxy-mu.intel.com:911

   # NOTE, only ovn-controller can works, but nfn-agent can not install python ovs package.
   kubectl -n $NM exec -it ${NFNA} -- bash -c "http_proxy=$H_PROXY dnf install -y python3-pip"
   kubectl -n $NM exec -it ${NFNA} -- bash -c "pip3 --proxy $H_PROXY install ovs"
   kubectl -n $NM exec -it ${NFNA} -- bash -c "https_proxy=$H_PROXY http_proxy=$H_PROXY wget https://raw.githubusercontent.com/openvswitch/ovs/master/utilities/ovs-tcpdump.in -O ovs-tcpdump.in"

   kubectl -n $NM exec -it ${NFNA} -- bash -c "http_proxy=$H_PROXY yum install -y tcpdump"

   ```

## usage
   ```
   kubectl -n $NM exec -it ${NFNA} -- ovs-vsctl list-br
   kubectl -n $NM exec -it ${NFNA} -- ovs-vsctl list-ports br-int

   IFC=ovn4nfv0-85000f
   kubectl -n $NM exec -it ${NFNA} -- bash -c "python3 ovs-tcpdump.in  -i $IFC --db-sock unix:/var/run/openvswitch/db.sock"

   ```
