#!/bin/bash

function checkroot {
  [ `whoami` = root ] || { echo "Please run as root"; exit 0; }
}

function killrunning {
  pkill -9 -f "[d]omain-server" > /dev/null 2>&1
  pkill -9 -f "[a]ssignment-client" > /dev/null 2>&1
}

checkroot
killrunning
exit 0
