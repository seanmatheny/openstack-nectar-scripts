#!/bin/bash
#fall_in.sh: script to get undercloud instances on respective/correct hosts
source /root/ucadmin
OPENSTACK='/root/pyvenv3/bin/openstack'
NOVA='/root/pyvenv3/bin/nova'
LOGGER='/usr/bin/logger'

for NUM in 1 2 3
do
  for VM in $($OPENSTACK server list --host uc0${NUM} -f value -c Name)
  do
    MVM=$(echo $VM | grep -Po '0\K[^\.]*')
    if [[ ! -z $MVM ]] && [[ $MVM != $NUM ]]
    then
      echo "we need to migrate $VM to uc0${MVM}"
      $LOGGER fall_in.sh: We need to migrate $VM to uc0${MVM}
      $NOVA live-migration --block-migrate $VM uc0${MVM} 2>&1 | $LOGGER &
    else
      echo "$VM is already on uc0${MVM}, or isn't elligible"
    fi
  done
done
