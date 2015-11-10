#!/bin/bash

# Home Directory for HifiUser
HIFIDIR="/home/hifi"
# Runtime Directory Location
RUNDIR="$HIFIDIR/run"
# Log Directory
LOGSDIR="$HIFIDIR/logs"
# Source Storage Dir
SRCDIR="/usr/local/src"
# Config File Name
CFGNAME="/etc/.chifi"
# Our lock file name
LOCKFILE="/etc/.chifilock"
#TESTING
#NEWHIFI=1

## Functions ##
function checkroot {
  [ `whoami` = root ] || { echo "Please run as root"; exit 1; }
}

function killrunning {
  pkill -9 -f "[d]omain-server" > /dev/null 2>&1
  pkill -9 -f "[a]ssignment-client" > /dev/null 2>&1
}

function createuser {
  # Creating our lockfile
  touch $LOCKFILE
  if [[ $(grep -c "^hifi:" /etc/passwd) = "0" ]]; then
    adduser --system --shell /bin/bash --disabled-password --group --home /home/hifi hifi
    NEWHIFI=1
  fi
}

function doapt {
  [[ "$SILENT" -eq "0" ]] && { echo "Installing needed files for compile"; }
  apt-get update -y

apt-get install -y screen git zlib1g-dev libssl-dev libstdc++6 freeglut3 freeglut3-dev mesa-common-dev libxrandr-dev \
libudev-dev libxslt1.1 libpulse0 libgstreamer0.10-0 libgstreamer-plugins-base0.10-0 libicu52 libxcomposite1 -y

}

function compilehifi {
  if [[ -d "$SRCDIR" ]]; then
    pushd $SRCDIR > /dev/null

    if [[ ! -d "highfidelity" ]]; then
      mkdir highfidelity
    fi

    cd highfidelity

    if [[ ! -d "hifi" ]]; then
      git clone https://github.com/highfidelity/hifi.git
      NEWHIFI=1
    fi

    popd > /dev/null
    pushd $SRCDIR/highfidelity/hifi > /dev/null

    # Future todo - add a forcable call to the shell script to override this
    if [[ $(git pull) =~ "Already up-to-date." ]]; then
      [[ "$SILENT" -eq "0" ]] && { echo "Already up to date with last commit."; }
    else
      NEWHIFI=1
    fi

    if [[ $NEWHIFI -eq 1 ]]; then
      [[ "$SILENT" -eq "0" ]] && { echo "Source needs compiling."; }
      killrunning
      # we are still assumed to be in hifi directory
      if [[ -d "build" ]]; then
        rm -rf build/*
      else
        mkdir build
      fi
      cd build
      cmake ..

      make domain-server
      if [ $? -eq 0 ]; then
        [[ "$SILENT" -eq "0" ]] && { echo "DS Build was successful!"; }

      else
        [[ "$SILENT" -eq "0" ]] && { echo "DS Build Failed!"; }
        exit 1
      fi

      make assignment-client
      if [ $? -eq 0 ]; then
        [[ "$SILENT" -eq "0" ]] && { echo "AC Build was successful!"; }
      else
        [[ "$SILENT" -eq "0" ]] && { echo "AC Build Failed!"; }
        exit 1
      fi

    fi
    # ^ Ending the git pull check

    # popd on hifi source dir
    popd > /dev/null
  fi
}

function setuphifidirs {

  pushd $HIFIDIR > /dev/null

  if [[ ! -d $RUNDIR ]]; then
    [[ "$SILENT" -eq "0" ]] && { echo "Creating Runtime Directory"; }
    mkdir $RUNDIR
  fi

  if [[ ! -d $LOGSDIR ]]; then
    mkdir $LOGSDIR
  fi

  popd > /dev/null

}

function movehifi {
  # least error checking here, we pretty much assume that if this is a new compile per the flag
  # then you have all the proper folders and files already.
  if [[ $NEWHIFI -eq 1  ]]; then
    killrunning
    DSDIR="$SRCDIR/highfidelity/hifi/build/domain-server"
    ACDIR="$SRCDIR/highfidelity/hifi/build/assignment-client"
    cp $DSDIR/domain-server $RUNDIR
    cp -R $DSDIR/resources $RUNDIR
    cp $ACDIR/assignment-client $RUNDIR
    changeowner
  fi
}

function changeowner  {
  if [ -d "$HIFIDIR" ]; then
    chown -R hifi:hifi $HIFIDIR
  fi
}

#function checkifrunning {
  # Not used now, but in the future will check if ds/ac is running then offer to restart if so
  # For now we just auto restart.
  #[[ $(pidof domain-server) -gt 0 ]] && { HIFIRUNNING=1; }
#}

function handlerunhifi {
  #checkifrunning
  #if [[ $NEWHIFI -eq 1 || HIFIRUNNING -eq 1 ]]; then
  [[ "$SILENT" -eq "0" ]] && { echo "Running your HiFi Stack as user hifi"; }
  touch $CFGNAME
  # Delete our lockfile 
  rm -rf $LOCKFILE

  if [ "$NEWHIFI" -eq "1" ]; then
    killrunning
    export -f runashifi
    su hifi -c "bash -c runashifi"
  fi

  exit 0
  #fi
}

function runashifi {
  # Everything here is run as the user hifi
  #TIMESTAMP=$(date '+%F')
  HIFIDIR=/home/hifi
  HIFIRUNDIR=$HIFIDIR/run
  #HIFILOGDIR=$HIFIDIR/logs
  cd $HIFIRUNDIR
  screen -h 1024 -dmS hifi ./domain-server
  screen -h 1024 -dmS hifi ./assignment-client -n 3
  #./domain-server &>> $HIFILOGDIR/domain-$TIMESTAMP.log&
  #./assignment-client -n 3 &>> $HIFILOGDIR/assignment-$TIMESTAMP.log&
}

function handlerc {
  if [[ $(grep -c "^. ~/.coalrc" ~/.bashrc) = "0" ]]; then
    echo ". ~/.coalrc" >> ~/.bashrc
  fi

cat <<EOF > ~/.coalrc
alias killhifi='bash <(curl -Ls https://raw.githubusercontent.com/nbq/hifi-compile-scripts/master/centos7-kill-hifi.sh)'
alias compilehifi='bash <(curl -Ls https://raw.githubusercontent.com/nbq/hifi-compile-scripts/master/ubuntu-aws.sh)'
alias runhifi='bash <(curl -Ls https://raw.githubusercontent.com/nbq/hifi-compile-scripts/master/ubuntu-run-hifi.sh)'
EOF

}

function checkauto {

  if [ ! -f $CFGNAME ]; then
    # We have not been ran the first time yet
    if [ "$SILENT" -eq "1" ]; then
      # Exit only if we are running in silent mode here
      exit 1
    fi  
  fi

}

function checklockfile {
  if [ -f $LOCKFILE ]; then
    [[ "$SILENT" -eq "0" ]] && { echo "We are already doing a compile"; }
    exit 1
  fi
}

# Steps to create the magic

# Catch if we are running silent or not
if [ ! -z $1 ]
then
  if [ "$1" -eq "1" ]; then
    SILENT=1
  fi
else
  SILENT=0
fi

checklockfile

checkauto

checkroot

createuser

[[ "$SILENT" -eq "0" ]] && { doapt; }

setuphifidirs

compilehifi

movehifi

handlerc

handlerunhifi
