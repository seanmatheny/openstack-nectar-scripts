#!/bin/bash
#script to auto activate Nectar project trials if use is a masters student, PhD candi$DATE, or staff
#based on LDAP group membership
#
##
#requirements for pip openstack modules
source /etc/profile
cd /root/nectar/nectar-tools
#this can be any venv with openstack modules installed
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
TOUCHFILE='/tmp/nectarpts.running'
PREVPTDIR='/root/nectar/lastpt'
prevpt=$(cat /root/nectar/lastpt)
#prevet running if lastpt is empty (will fail if file doesn't exist)
if [ -s $PREVPTDIR ]
 then 
  if [ ! -f $TOUCHFILE ] 
  then
    #touchfile to prevent Sean getting embarrased again
    touch $TOUCHFILE
    ##-get list of all nz project trials (pts)
    pts=$($OS project list --domain nz --format value | $GREP pt-|$SED 's/[^ ]* ...//'| $SORT -n)
    ##-save last project trial for updating lastpt file after run
    lastpt=$(echo ${pts} | $GREP -Eo '[0-9]+$')
    for pt in $pts
    do 
      ##-only run this on new pts - 30/8/19 make sure to use -gt and not >!!
      if [[ $pt -gt $prevpt ]]
      then  
        echo "$pt is greater than $prevpt, so is a new user"
        # echo "$pt (every one)"
        ##-get user's email from project - this could potentially fail if >1 user in project, but this shouldn't be the case ever
        prouser=$($OS role assignment list --project pt-${pt} --names --format value)
        if [[ ! $prouser =~ "Auckland-Access" ]]
        then
          echo "$pt does not have AA role"
          newemail="$(echo ${prouser} | $AWK '{print $2}' | $CUT -f1,2 -d'@')"
          # echo "user email from project$newemail"
          ##-search ldap to see if user is a current masters, phd, or staff researcher
          if $LDAPSEARCH -H $LDAPCONN -x -D $LDAPUSER -w $LDAPPASS -b $LDAPBASE "(mail=${newemail})" memberOf | $GREP -qe "\.7[0-9]{2}.*now" -qe PhD.now -qe staff.uos
          then
	    ##-user is legit, add auckland-access role, send email to us to notify, as well as onbording email to user
            echo "$OS role add --user ${newemail} --project pt-${pt} Auckland-Access"
            $OS role add --user ${newemail} --project pt-${pt} Auckland-Access
            echo "$($DATE "+%m/%d/%y %T") ${newemail}" >> /var/log/ptusersadded.log
            echo "user $newemail is legit, adding role"
            echo "New Project Trial Nectar user: ${newemail}" | /usr/bin/mail -s "New Project Trial Nectar User: ${newemail}" $EMAIL
            /usr/bin/mailx -a 'Content-Type: text/html' -s "Welcome to the NeCTAR Research Cloud at University of Auckland" ${newemail} < /root/nectar/email_onboard.html
            #below for testing - sean
            #/usr/bin/mailx -a 'Content-Type: text/html' -s "Welcome to the NeCTAR Research Cloud at University of Auckland ${newemail}" s.matheny@auckland.ac.nz < /root/nectar/email_onboard.html
          else
            echo "user $newemail does not appear to be legit"
            #send explanation email for users who don't appear to be legit
            /usr/bin/mailx -a 'Content-Type: text/html' -s "Welcome to the NeCTAR Research Cloud at University of Auckland" ${newemail} < /root/nectar/email_reject.html
          fi
        fi 
      fi
    done
#update last pt number to begin from here next time
echo $lastpt > /root/nectar/lastpt
rm $TOUCHFILE
  fi
  else
    echo "lastpt file is empty, refusing to run to prevent my master Sean's embarrasment"
fi
#proof of run
echo "$($DATE "+%m/%d/%y %T") ran" >> /var/log/ptusersadded.log
