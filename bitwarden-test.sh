#!/usr/bin/env bash
set -e

cat << "EOF"
                 _ _       _     _ _                         _
 ___  ___  _   _| ( )___  | |__ (_) |___      ____ _ _ __ __| | ___ _ __
/ __|/ _ \| | | | |// __| | '_ \| | __\ \ /\ / / _` | '__/ _` |/ _ \ '_ \
\__ \ (_) | |_| | | \__ \ | |_) | | |_ \ V  V / (_| | | | (_| |  __/ | | |
|___/\___/ \__,_|_| |___/ |_.__/|_|\__| \_/\_/ \__,_|_|  \__,_|\___|_| |_|
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
https://www.soulseekkor.com, https://github.com/soulseekkor

===================================================

EOF

# Setup

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_NAME=$(basename "$0")
SCRIPT_PATH="$DIR/$SCRIPT_NAME"
OUTPUT="$DIR/bwdata"
if [ $# -eq 2 ]
then
    OUTPUT=$2
fi
if command -v docker-compose &> /dev/null
then
    dccmd='docker-compose'
else
    dccmd='docker compose'
fi

SCRIPTS_DIR="$OUTPUT/scripts"
BITWARDEN_SCRIPT_URL="https://raw.githubusercontent.com/SoulSeekkor/bitwarden-scripts/master/bitwarden-test.sh"
RUN_SCRIPT_URL="https://raw.githubusercontent.com/SoulSeekkor/bitwarden-scripts/master/run.sh"

# Please do not create pull requests modifying the version numbers.
COREVERSION="test"
WEBVERSION="test"
KEYCONNECTORVERSION="test"

echo "bitwarden.sh version $COREVERSION"
docker --version
if [[ "$dccmd" == "docker compose" ]]; then
    $dccmd version
else
    $dccmd --version
fi

echo ""

# Functions

function downloadSelf() {
    if curl -L -s -w "http_code %{http_code}" -o $SCRIPT_PATH.1 $BITWARDEN_SCRIPT_URL | grep -q "^http_code 20[0-9]"
    then
        mv -f $SCRIPT_PATH.1 $SCRIPT_PATH
        chmod u+x $SCRIPT_PATH
    else
        rm -f $SCRIPT_PATH.1
    fi
}

function downloadRunFile() {
    if [ ! -d "$SCRIPTS_DIR" ]
    then
        mkdir $SCRIPTS_DIR
    fi
    curl -L -s -o $SCRIPTS_DIR/run.sh $RUN_SCRIPT_URL
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
    if [ -d "$OUTPUT/docker" ]
    then
        echo "Looks like Bitwarden is already installed at $OUTPUT."
        exit 1
    fi
}

function compressLogs() {
    LOG_DIR=${1#$(pwd)/}/logs
    START_DATE=$2
    END_DATE=$3
    tempfile=$(mktemp)

    function validateDateFormat() {
        if ! [[ $1 =~ ^[0-9]{8}$ ]]; then
            echo "Error: $2 date format is invalid. Please use YYYYMMDD."
            exit 1
        fi
    }

    function validateDateOrder() {
        if [[ $(date -d "$1" +%s) > $(date -d "$2" +%s) ]]; then
            echo "Error: start date ($1) must be earlier than end date ($2)."
            exit 1
        fi
    }

    # Validate start date format
    if [ -n "$START_DATE" ]; then
        validateDateFormat "$START_DATE" "start"
        if [ -z "$END_DATE" ]; then
            echo "Error: an end date is required when an start date is provided."
            exit 1
        fi
    fi
    
    # Validate end date format and order
    if [ -n "$END_DATE" ]; then
        validateDateFormat "$END_DATE" "end"
        validateDateOrder "$START_DATE" "$END_DATE"
    fi

    if [ -n "$START_DATE" ] && [ -n "$END_DATE" ]; then

        OUTPUT_FILE="bitwarden-logs-${START_DATE}-to-${END_DATE}.tar.gz"

        if [[ "$START_DATE" == "$END_DATE" ]]; then
            OUTPUT_FILE="bitwarden-logs-${START_DATE}.tar.gz"
        fi

        for d in $(seq $(date -d "$START_DATE" "+%Y%m%d") $(date -d "$END_DATE" "+%Y%m%d")); do
            # Find and list files matching the date in the filename and modification time, append to tempfile
            find $LOG_DIR \( -type f -name "*$d*.txt" -o -name "*.log" -newermt "$START_DATE" ! -newermt "$END_DATE" \) -exec bash -c 'echo "${1#./}" >> "$2"' _ {} "$tempfile" \;
        done

        echo "Compressing logs from $START_DATE to $END_DATE ..."
    else
        OUTPUT_FILE="bitwarden-logs-all.tar.gz"
        find $LOG_DIR -type f -exec bash -c 'echo "${1#./}" >> "$2"' bash {} "$tempfile" \;
        echo "Compressing all logs..."
    fi

    tar -czvf "$OUTPUT_FILE" -T "$tempfile"
    echo "Logs compressed into $(pwd $OUTPUT_FILE)/$OUTPUT_FILE"
    rm $tempfile
}

function listCommands() {
cat << EOT
Available commands:

install
start
restart
stop
update
updatedb
updaterun
updateself
updateconf
uninstall
renewcert
rebuild
compresslogs
help

See more at https://bitwarden.com/help/article/install-on-premise/#script-commands-reference

EOT
}

# Commands

case $1 in
    "install")
        checkOutputDirNotExists
        mkdir -p $OUTPUT
        downloadRunFile
        $SCRIPTS_DIR/run.sh install $OUTPUT $COREVERSION $WEBVERSION $KEYCONNECTORVERSION
        ;;
    "start" | "restart")
        checkOutputDirExists
        $SCRIPTS_DIR/run.sh restart $OUTPUT $COREVERSION $WEBVERSION $KEYCONNECTORVERSION
        ;;
    "update")
        checkOutputDirExists
        downloadRunFile
        $SCRIPTS_DIR/run.sh update $OUTPUT $COREVERSION $WEBVERSION $KEYCONNECTORVERSION
        ;;
    "rebuild")
        checkOutputDirExists
        $SCRIPTS_DIR/run.sh rebuild $OUTPUT $COREVERSION $WEBVERSION $KEYCONNECTORVERSION
        ;;
    "updateconf")
        checkOutputDirExists
        $SCRIPTS_DIR/run.sh updateconf $OUTPUT $COREVERSION $WEBVERSION $KEYCONNECTORVERSION
        ;;
    "updatedb")
        checkOutputDirExists
        $SCRIPTS_DIR/run.sh updatedb $OUTPUT $COREVERSION $WEBVERSION $KEYCONNECTORVERSION
        ;;
    "stop")
        checkOutputDirExists
        $SCRIPTS_DIR/run.sh stop $OUTPUT $COREVERSION $WEBVERSION $KEYCONNECTORVERSION
        ;;
    "renewcert")
        checkOutputDirExists
        $SCRIPTS_DIR/run.sh renewcert $OUTPUT $COREVERSION $WEBVERSION $KEYCONNECTORVERSION
        ;;
    "updaterun")
        checkOutputDirExists
        downloadRunFile
        ;;
    "updateself")
        downloadSelf && echo "Updated self." && exit
        ;;
    "uninstall")
        checkOutputDirExists
        $SCRIPTS_DIR/run.sh uninstall $OUTPUT
        ;;
    "compresslogs")
        checkOutputDirExists        
        compressLogs $OUTPUT $2 $3
        ;;
    "help")
        listCommands
        ;;
    *)
        echo "No command found."
        echo
        listCommands
esac