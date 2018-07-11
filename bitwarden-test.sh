#!/usr/bin/env bash
set -e

cat << "EOF"
                     ___          __    _ __                          __         
   _________  __  __/ ( )_____   / /_  (_) /__      ______ __________/ /__  ____ 
  / ___/ __ \/ / / / /|// ___/  / __ \/ / __/ | /| / / __ `/ ___/ __  / _ \/ __ \
 (__  ) /_/ / /_/ / /  (__  )  / /_/ / / /_ | |/ |/ / /_/ / /  / /_/ /  __/ / / /
/____/\____/\__,_/_/  /____/  /_.___/_/\__/ |__/|__/\__,_/_/   \__,_/\___/_/ /_/
                          __                   __   
                        _/  |_  ____   _______/  |_ 
                        \   __\/ __ \ /  ___/\   __\
                        |  | \  ___/ \___ \  |  |  
                        |__|  \___  >____  > |__|  
                                  \/     \/        

EOF

cat << EOF
Open source password management solutions
Copyright 2015-$(date +'%Y'), Soul's Services
https://soulseekkor.com, https://github.com/soulseekkor

===================================================

EOF

docker --version
docker-compose --version

echo ""

# Setup

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=`basename "$0"`
SCRIPT_PATH="$DIR/$SCRIPT_NAME"
OUTPUT="$DIR/bwdata"
if [ $# -eq 2 ]
then
    OUTPUT=$2
fi

SCRIPTS_DIR="$OUTPUT/scripts"
GITHUB_BASE_URL="https://raw.githubusercontent.com/SoulSeekkor/bitwarden-scripts/master"
COREVERSION="test"
WEBVERSION="test"

# Functions

function downloadSelf() {
    curl -s -o $SCRIPT_PATH $GITHUB_BASE_URL/bitwarden.sh
    chmod u+x $SCRIPT_PATH
}

function downloadRunFile() {
    if [ ! -d "$SCRIPTS_DIR" ]
    then
        mkdir $SCRIPTS_DIR
    fi
    curl -s -o $SCRIPTS_DIR/run.sh $GITHUB_BASE_URL/run.sh
    chmod u+x $SCRIPTS_DIR/run.sh
    rm -f $SCRIPTS_DIR/install.sh
}

function checkOutputDirExists() {
    if [ ! -d "$OUTPUT" ]
    then
        echo "Cannot find a Bitwarden installation at $OUTPUT."
        exit 1
    fi
}

function checkOutputDirNotExists() {
    if [ -d "$OUTPUT" ]
    then
        echo "Looks like Bitwarden is already installed at $OUTPUT."
        exit 1
    fi
}

# Commands

if [ "$1" == "install" ]
then
    checkOutputDirNotExists
    mkdir $OUTPUT
    downloadRunFile
    $SCRIPTS_DIR/run.sh install $OUTPUT $COREVERSION $WEBVERSION
elif [ "$1" == "start" -o "$1" == "restart" ]
then
    checkOutputDirExists
    $SCRIPTS_DIR/run.sh restart $OUTPUT $COREVERSION $WEBVERSION
elif [ "$1" == "update" ]
then
    checkOutputDirExists
    downloadRunFile
    $SCRIPTS_DIR/run.sh update $OUTPUT $COREVERSION $WEBVERSION
elif [ "$1" == "updatedb" ]
then
    checkOutputDirExists
    $SCRIPTS_DIR/run.sh updatedb $OUTPUT $COREVERSION $WEBVERSION
elif [ "$1" == "stop" ]
then
    checkOutputDirExists
    $SCRIPTS_DIR/run.sh stop $OUTPUT $COREVERSION $WEBVERSION
elif [ "$1" == "updateself" ]
then
    downloadSelf && echo "Updated self." && exit
else
    echo "No command found."
fi
