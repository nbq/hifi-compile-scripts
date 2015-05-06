#!/bin/bash

function checkroot {
  [ `whoami` = root ] || { echo "Please run as root"; exit 1; }
}

function killrunning {
  pkill -9 -f "[d]omain-server" > /dev/null 2>&1
  pkill -9 -f "[a]ssignment-client" > /dev/null 2>&1
}

function runashifi {
  # Everything here is run as the user hifi
  TIMESTAMP=$(date '+%F')
  HIFIDIR=/usr/local/hifi
  HIFIRUNDIR=$HIFIDIR/run
  HIFILOGDIR=$HIFIDIR/logs
  cd $HIFIRUNDIR
  ./domain-server &>> $HIFILOGDIR/domain-$TIMESTAMP.log&
  ./assignment-client -n 5 &>> $HIFILOGDIR/assignment-$TIMESTAMP.log&
}

checkroot
killrunning
export -f runashifi
su hifi -c "bash -c runashifi"
exit 0
