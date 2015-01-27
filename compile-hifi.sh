#!/bin/bash

# Home Directory for HifiUser
HIFIDIR="/usr/local/hifi"
# Last Compile Backup Directory
LASTCOMPILE="$HIFIDIR/last-compile"
# Runtime Directory Location
RUNDIR="$HIFIDIR/run"
# Log Directory
LOGSDIR="$HIFIDIR/logs"
# Source Storage Dir
SRCDIR="/usr/local/src"
# If this is 1 (true) then we need to handle the hifi init stuff
NEWHIFI=0

## Functions ##
function doyum {
  echo "Checking Yum Dependancies - Installing If Needed (will take a while)"
  yum install epel-release -y > /dev/null
  yum groupinstall "development tools" -y > /dev/null
  yum install openssl-devel git wget gzip freeglut* libXmu-* libXi-devel glew glew-devel tbb tbb-devel qt5-qt* -y > /dev/null
}

function killrunning {
  kill $(ps aux | grep '[d]omain-server' | awk '{print $2}')
  kill $(ps aux | grep '[a]ssignment-client' | awk '{print $2}')
}

function createuser {
  #HIFIUSER_EXISTS=$(grep -c "^hifi:" /etc/passwd)
  if [[ $(grep -c "^hifi:" /etc/passwd) = "0" ]]; then
    useradd -s /bin/bash -r -m -d $HIFIDIR hifi
    NEWHIFI=1
  fi
}

function removeuser {
  userdel -r hifi > /dev/null 2>&1
}

function changeowner  {
  if [ -d "$HIFIDIR" ]; then
    chown -R hifi:hifi $HIFIDIR
  fi  
}

function setuphifidirs {

  if [[ ! -d $HIFIDIR ]]; then
    echo "Creating $HIFIDIR"
    mkdir $HIFIDIR
    NEWHIFI=1
  fi

  # check if this is a new compile, otherwise move handle that process
  if [[ $NEWHIFI -eq 1 ]]; then
    pushd $HIFIDIR > /dev/null

    if [ ! -d "$LASTCOMPILE" ]; then
      echo "Creating Last-Compile Backup Directory"
      mkdir $LASTCOMPILE
    fi

    if [ ! -d "$RUNDIR" ]; then
      echo "Creating Runtime Directory"
      mkdir $RUNDIR
    fi

    if [[ -a "$RUNDIR/assignment-client" && -a "$RUNDIR/domain-server" && -d "$RUNDIR/resources" ]]; then
      echo "Removing Old Last-Compile Backup"
      rm -rf $LASTCOMPILE/*

      echo "Backing Up AC"
      mv "$RUNDIR/assignment-client" $LASTCOMPILE

      echo "Backing Up DS"
      mv "$RUNDIR/domain-server" $LASTCOMPILE

      echo "Making a Copy Of The Resources Folder"
      cp -R "$RUNDIR/resources" $LASTCOMPILE
    fi

    if [[ ! -d $LOGSDIR ]]; then
      mkdir $LOGSDIR
    fi
    popd > /dev/null
  fi
}

function handlecmake {
  if [ ! -f "cmake-3.0.2.tar.gz" ]; then
    wget http://www.cmake.org/files/v3.0/cmake-3.0.2.tar.gz
    tar -xzvf cmake-3.0.2.tar.gz
    cd cmake-3.0.2/
    ./configure --prefix=/usr
    gmake && gmake install
  fi
}

function handleglm {
  if [ ! -d "/usr/include/glm" ]; then
    wget http://softlayer-dal.dl.sourceforge.net/project/ogl-math/glm-0.9.5.4/glm-0.9.5.4.zip
    unzip glm-0.9.5.4.zip
    mv glm/glm /usr/include
  fi
}

function handlebullet {
  if [ ! -f "Bullet-2.83-alpha.tar.gz" ]; then
    wget https://github.com/bulletphysics/bullet3/archive/Bullet-2.83-alpha.tar.gz
    tar -xzvf Bullet-2.83-alpha.tar.gz
    cd bullet3-Bullet-2.83-alpha/
    cmake -G "Unix Makefiles"
    make && make install
    cd ..
  fi
}

function compilehifi {
  # NOTE - This currently assumes /usr/local/src and does not move forward if the source dir does not exist - todo: fix
  if [[ -d "$SRCDIR" ]]; then
    pushd $SRCDIR > /dev/null

    # handle install and compile of cmake
    if [[ ! -f "/usr/bin/cmake"  ]]; then
      handlecmake
    fi

    # Handle GLM Check/Install
    handleglm
     
    # Handle BulletSim
    # Check for a file from the default BulletSim Install
    if [[ ! -a "/usr/local/lib/cmake/bullet/UseBullet.cmake" ]]; then
      handlebullet
    fi

    if [[ ! -d "highfidelity" ]]; then
      mkdir highfidelity
    fi

    cd highfidelity

    if [[ ! -d "gverb" ]]; then
      git clone https://github.com/highfidelity/gverb.git
    else
      # assumes this is the proper git directory, could check for .git folder to verify
      cd gverb
      git pull > /dev/null
      cd ..
    fi

    if [[ ! -d "hifi" ]]; then
      git clone https://github.com/highfidelity/hifi.git
    fi
    
    # popd src
    popd > /dev/null
    pushd $SRCDIR/highfidelity/hifi > /dev/null 
  
    # Link gverb libs in with hifi interface directory
    if [ ! -L "$SRCDIR/highfidelity/hifi/interface/external/gverb/src" ]; then
      ln -s $SRCDIR/highfidelity/gverb/src $SRCDIR/highfidelity/hifi/interface/external/gverb/src
    fi
    if [ ! -L "$SRCDIR/highfidelity/hifi/interface/external/gverb/include" ]; then
      ln -s $SRCDIR/highfidelity/gverb/include $SRCDIR/highfidelity/hifi/interface/external/gverb/include
    fi

    # Future todo - add a forcable call to the shell script to override this
    UPTODATE="Already up-to-date."
 
    if [[ "$(git pull)"=="$UPTODATE" ]]; then
      echo "Already up to date with last commit."
    else
      echo "Source needs compiling."
      NEWHIFI=1
      # we are still assumed to be in hifi directory
      if [ -d "build" ]; then
        rm -rf build/*
      else
        mkdir build
      fi
      cd build
      cmake ..
      make domain-server && make assignment-client
    fi 
    # ^ Ending the git pull check

    # popd on hifi source dir
    popd > /dev/null
  fi
}

function movehifi {
  # least error checking here, we pretty much assume that if this is a new compile per the flag
  # then you have all the proper folders and files already.
  if [[ $NEWHIFI -eq 1  ]]; then
    DSDIR="$SRCDIR/highfidelity/hifi/build/domain-server"
    ACDIR="$SRCDIR/highfidelity/hifi/build/assignment-client"
    cp $DSDIR/domain-server $RUNDIR
    cp -R $DSDIR/resources $RUNDIR
    cp $ACDIR/assignment-client $RUNDIR
    changeowner
  fi
}

## End Functions ##

# Handle Yum Install Commands
doyum

# Deal with the source code and compile highfidelity
compilehifi

# Make our HiFi user if needed
createuser

# setup hifi folders
setuphifidirs

# copy new binaries then change owner
movehifi
