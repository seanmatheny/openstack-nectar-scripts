#!/bin/bash
#change image shared with multiple projects (e.g. one that is frequently updated)
$OLDIMAGE = $1
$NEWIMAGE = $2
$MEMBERLIST = '/tmp/member_list'
openstack image member list $OLDIMAGE --format value | cut -d " " -f 2 > $MEMBERLIST
while read PROJECT
do
        openstack image remove project $OLDIMAGE $PROJECT
        openstack image add project $NEWIMAGE $PROJECT
        openstack image set --accept $NEWIMAGE --project $PROJECT
done < $MEMBERLIST
