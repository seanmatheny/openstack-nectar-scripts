#!/bin/bash
#script to add Auckland-Access role to user/projects 
#if user is a masters student, PhD candi$DATE, or staff
#based on ldap group membership
#
##
#requirements for pip openstack modules
source /etc/profile
cd /root/nectar/nectar-tools
#below could be any venv with openstack 
source /root/nectar/nectar-tools/bin/activate
#
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppetlabs/bin
source /root/nectar/rcadmin
source /root/nectar/ldapcreds
EMAIL='nectaralerts@uoa.auckland.ac.nz'
OS='/root/nectar/nectar-tools/bin/openstack'
LDAPSEARCH='/usr/bin/ldapsearch'
DATE='/bin/date'
prevpt=$(cat /root/nectar/lastpt)
AWK='/usr/bin/awk'
GREP='/bin/grep'
CUT='/usr/bin/cut'
SORT='/usr/bin/sort'
SED='/bin/sed'
TOUCHFILE='/tmp/nectaraklrole.running'
if [ ! -f $TOUCHFILE ]
then
  touch $TOUCHFILE
  for project in $(${OS} project list --domain nz --format value | grep -v 'pt-' | cut -d " " -f 1)
  do
    #echo $i
    for user in $(${OS} role assignment list --project ${project} --names --format value | cut -d " " -f 2|sort | uniq)
    do
      if ${OS} role assignment list --user ${user:0:-8} --project ${project} --names| grep Auckland-Access
      then
        echo "user has AA"
      else
        echo "user does not have AA"
        if $LDAPSEARCH -H $LDAPCONN -x -D $LDAPUSER -w $LDAPPASS -b $LDAPBASE "(mail=${user:0:-8})" memberOf | $GREP -qe "\.7[0-9]{2}.*now" -qe PhD.now -qe staff.uos
        then
          echo "user is legit, add auckland-access role:"
          echo "${OS} role add --user ${user:0:-8} --project ${project} Auckland-Access"
          ${OS} role add --user ${user:0:-8} --project ${project} Auckland-Access
        #$OS role add --user ${newemail} --project pt-${pt} Auckland-Access
        echo "$($DATE "+%m/%d/%y %T") ${newemail}" >> /var/log/ptusersadded.log
        #echo "New Project Trial Nectar user: ${newemail}" | /usr/bin/mail -s "New Project Trial Nectar User: ${newemail}" $EMAIL
      #else
        #echo "user $u is not legit"
        fi
      fi
    done
  done
  rm -f $TOUCHFILE
fi
