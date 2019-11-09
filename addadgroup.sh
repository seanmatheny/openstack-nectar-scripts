#!/bin/bash
#script to add users of a group to a project
#will keep an ldap group in sync (one way) with openstack project
#requirements for pip openstack modules
source /etc/profile
cd /root/nectar/nectar-tools
#below could be and venv with openstack pip installed
source /root/nectar/nectar-tools/bin/activate
#set the following 3 variables to suit
GROUPSLIST=~/nectar/adgroups.txt
source /root/nectar/rcadmin
PROJECT=stats-incubator
NECTAREMAIL='nectarinfo@auckland.ac.nz'
####
LDAPUSER=''
LDAPPASS=''
LDAPCONN=ldaps://uoa.auckland.ac.nz
LDAPBASE=dc=uoa,dc=auckland,dc=ac,dc=nz
OS='/root/nectar/nectar-tools/bin/openstack'
TOUCHFILE='/tmp/nectarstatsaddgroup.running'
if [ ! -f $TOUCHFILE ]
then
  #touchfile to prevent Sean getting embarrased
  touch $TOUCHFILE
  while read adgroups
  do
    TARGETGROUP=${adgroups}
    UPIS=`ldapsearch -H $LDAPCONN -x -D $LDAPUSER -w $LDAPPASS -b $LDAPBASE "(cn=$TARGETGROUP)" member |grep -e member: |cut -c12- |sed 's/,/ /g' |awk '{print $1}'`
    for UPI in $UPIS
      do
        USERDATA=`ldapsearch -H $LDAPCONN -x -D $LDAPUSER -w $LDAPPASS -b $LDAPBASE "(sAMAccountname=$UPI)" displayName uidNumber gidNumber mail |grep -e displayName: -e uidNumber: -e gidNumber: -e mail:`
        EMAIL=$(echo "$USERDATA" |grep -e "mail:" |sed 's/mail: //g')
        echo $EMAIL
        $OS role add --user ${EMAIL} --project ${PROJECT}  member
        $OS role add --user ${EMAIL} --project ${PROJECT}  Auckland-Access
        echo "New User in the Stats Incubator Project: ${EMAIL}" | /usr/bin/mail -s "New User on the Nectar Stats Incubator Project: ${EMAIL}" $NECTAREMAIL
      done
  rm -f $TOUCHFILE
  done < ${GROUPSLIST}
fi
exit 0
