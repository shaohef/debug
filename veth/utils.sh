#!/bin/bash

# https://www.cnblogs.com/shaohef/p/14087959.html
# NOTE: ref this file

# Get namespace 
id2ns()
{
LKNSID=${1}
cat <<EOF | python3
import psutil
import os
import pyroute2
from pyroute2.netlink import rtnl, NLM_F_REQUEST
from pyroute2.netlink.rtnl import nsidmsg
from nsenter import Namespace

# phase I: gather network namespaces from /proc/[0-9]*/ns/net
netns = dict()
for proc in psutil.process_iter():
    netnsref= '/proc/{}/ns/net'.format(proc.pid)
    netnsid = os.stat(netnsref).st_ino
    if netnsid not in netns:
        netns[netnsid] = netnsref

# phase II: ask kernel "oracle" about the local IDs for the
# network namespaces we've discovered in phase I, doing this
# from all discovered network namespaces
for id, ref in netns.items():
    with Namespace(ref, 'net'):
        ipr = pyroute2.IPRoute()
        for netnsid, netnsref in netns.items():
            with open(netnsref, 'r') as netnsf:
                req = nsidmsg.nsidmsg()
                req['attrs'] = [('NETNSA_FD', netnsf.fileno())]
                resp = ipr.nlm_request(req, rtnl.RTM_GETNSID, NLM_F_REQUEST)
                local_nsid = dict(resp[0]['attrs'])['NETNSA_NSID']
            if local_nsid == $LKNSID:
                print(netnsid)
                break
EOF
}

# Get PID for namespace  
ns2pid(){
  echo $(lsns |grep $1|awk '{print $4}')
}

dev2peernsid(){
  echo $(ip -o l |grep $1 | awk '{match($0, /.+link-netnsid\s([^ ]*)/, a);print a[1];exit}')
}

dev2peerpid(){
  nsid=$(ip -o l |grep $1| awk '{match($0, /.+link-netnsid\s([^ ]*)/, a);print a[1];exit}')
  echo $(lsns |grep $(id2ns $nsid)|awk '{print $4}') 
}

dev2peerip(){
  pid=$(dev2peerpid $1)
  PEER=$(nsdev2peer $1)
  IP=$(nsenter -t $pid -n ip -o -c -4 a show dev ${PEER%@*} | awk '{match($0, /inet\s([^ ]*)/, a);print a[1];exit}') 
  echo ${IP%/*}
}

ipnet2dev(){
  echo $(ip route | grep $1 | awk '{match($0, /.+dev\s([^ ]*)/, a);print a[1];exit}')
}

dev2ipnet(){
  echo $(ip route | grep $1| awk '{print $1}')
}

devtype(){
  echo $(ethtool -i $1| grep "driver:" |awk '{print $2}')
}

# https://unix.stackexchange.com/questions/441876/how-to-find-the-network-namespace-of-a-veth-peer-ifindex
# ifindex=$(nsenter -t $pid -n ip link | sed -n -e 's/.*eth0@if\([0-9]*\):.*/\1/p')
ifindex(){
  echo $( ip link | sed -n -e 's/.*'"$1"'@if\([0-9]*\):.*/\1/p')
}


# veth=$(ip -o link | grep ^$ifindex | sed -n -e 's/.*\(veth[[:alnum:]]*@if[[:digit:]]*\).*/\1/p')
vethpeer(){
  echo $(ip -o link | grep ^$1 | sed -n -e 's/.*\(veth[[:alnum:]]*@if[[:digit:]]*\).*/\1/p')
}

index2peer(){
  for peer in `ls /sys/class/net/`; do
    INDEX=`cat /sys/class/net/$peer/ifindex`
    if [[ $INDEX == $1 ]]; then
      echo $peer 
      return 0
    fi
  done
  echo "Error, not find peer"
  return 1
}

index2peer(){
  echo $(ip -o link | grep ^${1}: | awk -F'[: ]' '{print $3}')
}

# for namesapce 
# nsenter -t $pid -n ip -o link | grep ^4: | sed -n -e 's/.*: \(.*@if[[:digit:]]*\).*/\1/p'
# usage:
# index2peer $link_index $pid
nsindex2peer(){
  echo $(nsenter -t ${2} -n ip -o link | grep ^${1}: | awk -F'[: ]' '{print $3}') 
}

ipnet2peer(){
  echo $(index2peer $(ifindex $(ipnet2dev $1)))
}

# nsipnet2peer 10.243.179.114 
nsipnet2peer(){
  pid=$(dev2peerpid $(ipnet2dev $1) )
  echo $(nsindex2peer $(ifindex $(ipnet2dev $1)) $pid) 
}

#  similar to vethpeer cali8f43c28540a in same namespace
# nsipnet2peer cali8f43c28540a
nsdev2peer(){
  pid=$(dev2peerpid $1)
  echo $(nsindex2peer $(ifindex $1) $pid) 
}


# NOTE(shaohe): need to move out of this file
function getpodip()
{
  PODINFO=`kubectl get pod -A -o wide |grep $1`
  NMSP=`awk '{print $1}' <<< $PODINFO`
  NM=`awk '{print $2}' <<< $PODINFO`
  echo $(kubectl -n $NMSP get pod $NM -o=jsonpath='{.status.podIP}')
}

pid2cid(){
  echo $(docker ps -q | xargs docker inspect --format '{{.State.Pid}}, {{.ID}}' | grep "^${1},")
}

pid2cname(){
  DOCINFO=$(cat /proc/${1}/cgroup |head -n 1)
  DOCINFO=${DOCINFO##*-}
  DOCINFO=${DOCINFO%%.*}
  echo $(docker inspect --format '{{.Name}}' ${DOCINFO} | sed 's/^\///')
}

dev2peercname(){
  echo $(pid2cname $(dev2peerpid $1))
}

# something wrong with pid2cid , can not works
dev2peercid(){
  echo $(pid2cid $(dev2peerpid $1))
}
