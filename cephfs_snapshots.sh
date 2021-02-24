"~/cephfs_snapshots.sh" 38L, 934C                                                          13,8          All
#!/bin/bash
DOW=$(/bin/date +%u)
EMAIL='s.matheny@auckland.ac.nz'
BASEPATH='/mnt/cephfs/.snap/Snapshot_'
##Let's start
#script to take nightly and weekly snapshots in cephfs/nfs
#no way to rename old ones, so we'll just remove and create for now
#delete old snap for this SUFFIX
if [ $DOW -eq 6 ]
then
  echo "It's Saturday, time to party and take a weekly backup!" $LOG
  SUFFIX='Weekly'
else
  echo "It's not Saturday, take a nightly backup" $LOG
  SUFFIX='Nightly'
fi
##dow down
rmdir ${BASEPATH}${SUFFIX}
if [ $? -eq 0 ]
then
  echo "+There was a previous $SUFFIX snap, and it has been deleted"
else
  ERRORS=1
fi
echo "+Taking $SUFFIX snap"
mkdir ${BASEPATH}${SUFFIX}
if [ $? -eq 0 ]
then
  echo "+Snapshot created successfully"
else
  ERRORS=1
fi

if [[ $ERRORS -eq 1 ]]
then
  echo "Snapshot job on had errors-- better check it." | /usr/bin/mail -s "Backup job on TSM node for project had errors." $EMAIL
fi
