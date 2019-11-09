#!/bin/bash
#email notification of new nectar openstack project requests
#
source /etc/profile
#vars
emailrec="nectaralerts@uoa.auckland.ac.nz"
tmpemail=/tmp/email
osbin=/root/nectar/nectar-tools/bin/openstack
IFS=$'\n'
touchfile='/tmp/nectargetnewrequests.running'
#only run if not already running
if [ ! -f $touchfile ]
then
  touch $touchfile
  #run openstack command 
  source /root/nectar/rcadmin
  for project in $(${osbin} allocation list --format value | grep -E 'Submitted|Update requested' | grep auckland)
  do 
    id=$(awk '{split($0, a); print a[1]}' <<< $project)
    pname=$(awk '{split($0, a); print a[2]}' <<< $project)
    email=$(awk '{split($0, a); print a[3]}' <<< $project)
    rtype=$(awk '{split($0, a); print a[4]}' <<< $project)
    # change language to be more readable
    if [[ $rtype == "Submitted" ]]
    then
      rtype2="new request"
    else
      rtype2="change request"
    fi
    #build and send email
    echo "There is a $rtype2 ready for review in Nectar:" > $tmpemail
    echo "--" >> $tmpemail
    echo "Project id: $id" >> $tmpemail
    echo "Project Name: $pname" >> $tmpemail
    echo "Researcher email: $email" >> $tmpemail
    echo "--" >> $tmpemail
    echo "Please log into the dashboard to review and action." >> $tmpemail
    cat $tmpemail | /usr/bin/mail -s "Nectar Project Request Pending" $emailrec
    #rm $tmpemail
  done
  rm -f $touchfile
fi
