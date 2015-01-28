#!/bin/bash

# todo: give user option to pick one of the default start sets from
# http://hifi-public.s3.amazonaws.com/content-sets/content-sets.html

# http://hifi-public.s3.amazonaws.com/content-sets/floating-island/models.svo
# ^path /1064.2,75.6,915.1/0.0000127922,0.71653,0.0000684642,0.697556

# http://hifi-public.s3.amazonaws.com/content-sets/bar/models.svo
# ^ path /1048.52,9.5386,1005.7/-0.0000565125,-0.395713,-0.000131155,0.918374

# http://hifi-public.s3.amazonaws.com/content-sets/space/models.svo
#path ^ /1000,100,100

function checkroot {
  [ `whoami` = root ] || { sudo "$0" "$@"; exit $?; }
}

function killrunning {
  kill $(ps aux | grep '[d]omain-server' | awk '{print $2}') > /dev/null 2>&1
  kill $(ps aux | grep '[a]ssignment-client' | awk '{print $2}') > /dev/null 2>&1
}

function runashifi {
  # Everything here is run as the user hifi
  TIMESTAMP=$(date '+%F')
  HIFIDIR=/usr/local/hifi
  HIFIRUNDIR=$HIFIDIR/run
  HIFILOGDIR=$HIFIDIR/logs
  cd $HIFIRUNDIR
  nohup ./domain-server &>> $HIFILOGDIR/domain-$TIMESTAMP.log&
  nohup ./assignment-client -n 4 &>> $HIFILOGDIR/assignment-$TIMESTAMP.log&
}

checkroot
killrunning
export -f runashifi
su hifi -c "bash -c runashifi"
exit 0
