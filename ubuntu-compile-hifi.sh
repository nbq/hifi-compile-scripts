#!/bin/bash

# Home Directory for HifiUser
HIFIDIR="/home/hifi"
# Runtime Directory Location
RUNDIR="$HIFIDIR/run"
# Log Directory
LOGSDIR="$HIFIDIR/logs"
# Source Storage Dir
SRCDIR="/usr/local/src"
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
  if [[ $(grep -c "^hifi:" /etc/passwd) = "0" ]]; then
    adduser --system --shell /bin/bash --disabled-password --group --home /home/hifi hifi
    NEWHIFI=1
  fi
}

function doapt {
  echo "Installing needed files for compile"
  apt-get update -y
  apt-get install screen git build-essential cmake qt5-default qtscript5-dev libssl-dev qttools5-dev qttools5-dev-tools -y
  apt-get install qtmultimedia5-dev libqt5svg5-dev libqt5webkit5-dev libsdl2-dev libasound2 libxmu-dev libxi-dev freeglut3-dev -y
  apt-get install libasound2-dev libjack-jackd2-dev libxrandr-dev libqt5xmlpatterns5-dev libqt5xmlpatterns5 -y
  apt-get install libqt5xmlpatterns5-private-dev qml-module-qtquick-controls -y
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

    # popd src
    popd > /dev/null
    pushd $SRCDIR/highfidelity/hifi > /dev/null

    # Future todo - add a forcable call to the shell script to override this
    if [[ $(git pull) =~ "Already up-to-date." ]]; then
      echo "Already up to date with last commit."
    else
      NEWHIFI=1
    fi

    if [[ $NEWHIFI -eq 1 ]]; then
      echo "Source needs compiling."
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
        echo "DS Build was successful!"

      else
        echo "DS Build Failed!"
        exit 1
      fi

      make assignment-client
      if [ $? -eq 0 ]; then
        echo "AC Build was successful!"
      else
        echo "AC Build Failed!"
        exit 1
      fi

    fi
    # ^ Ending the git pull check

    # popd on hifi source dir
    popd > /dev/null
  fi
}

function setuphifidirs {

  #if [[ ! -d $HIFIDIR ]]; then
  #  echo "Creating $HIFIDIR"
  #  mkdir $HIFIDIR
  #  NEWHIFI=1
  #fi

  # check if this is a new compile, otherwise move handle that process
  #if [[ $NEWHIFI -eq 1 ]]; then
  pushd $HIFIDIR > /dev/null

  if [[ ! -d $RUNDIR ]]; then
    echo "Creating Runtime Directory"
    mkdir $RUNDIR
  fi

  if [[ ! -d $LOGSDIR ]]; then
    mkdir $LOGSDIR
  fi

  popd > /dev/null
  #fi
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

function checkifrunning {
  # Not used now, but in the future will check if ds/ac is running then offer to restart if so
  # For now we just auto restart.
  [[ $(pidof domain-server) -gt 0 ]] && { HIFIRUNNING=1; }
}

function handlerunhifi {
  checkifrunning
  if [[ $NEWHIFI -eq 1 || HIFIRUNNING -eq 1 ]]; then
    echo "Running your HiFi Stack as user hifi"
    #echo "To update your install later, just type 'compilehifi' to begin this safe process again - NO DATA IS LOST"
    export -f runashifi
    su hifi -c "bash -c runashifi"
    exit 0
    #su - hifi -c "screen -h 1024 -dmS hifi ./domain-server"
  fi
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

cat <<EOF > ~/.coalrch
alias killhifi='bash <(curl -Ls https://raw.githubusercontent.com/nbq/hifi-compile-scripts/master/centos7-kill-hifi.sh)'
EOF
}

# Steps to create the magic

checkroot

createuser

doapt

setuphifidirs

compilehifi

movehifi

handlerc

handlerunhifi

