#!/bin/bash 
# Distributed under the MIT/X11 software license, see
# http://www.opensource.org/licenses/mit-license.php.
# Suppo Core developers, 18-03-2018

set -o history

#allow different coinds to make this potentially usable for other coin developers
COIN="suppo"
#COIND="suppod"
UPDATE_URL="https://api.github.com/repos/codeclock/sc/releases/latest"

echo -e "Installing unzip if it is missing (this may take some time)"
apt-get install sudo unzip -y
echo -e "Getting version information"
MACHINE_TYPE="linux"`getconf LONG_BIT`
ZIPNAME=`curl -s $UPDATE_URL | grep name |grep $MACHINE_TYPE | cut -d '"' -f 4`
VERNAME=${ZIPNAME::-12}

echo -e "Downloading: "$VERNAME

curl -s $UPDATE_URL | grep browser_download_url |grep $MACHINE_TYPE | cut -d '"' -f 4 | wget --show-progress -qi -
ERROR_CODE=$?
if [ $ERROR_CODE -ne 0 ]; then
    echo "Download failed, quitting"
    exit $ERROR_CODE 
fi
#extract the two required files
echo -e "Extracting required files"
unzip $ZIPNAME $VERNAME/${COIN}d $VERNAME/${COIN}-cli 
ERROR_CODE=$?

if [ $ERROR_CODE -ne 0 ]; then
    echo "Couldn't extract files, quitting"
    exit $ERROR_CODE
fi

PIDS=(`pidof ${COIN}d`)

for PID in "${PIDS[@]}"
do
    POWNER=`ps -o user= -p $PID`
    LOC=`readlink /proc/$PID/exe`
    LOC=${LOC::-6}

    echo -e "Updating files and restarting, allow about 2 mins"

    sudo -i -u $POWNER $LOC/${COIN}-cli stop
    sleep 30
    cp $VERNAME/${COIN}* $LOC/
    sleep 30
    sudo -i -u $POWNER $LOC/${COIN}d

done

rm -rdf $VERNAME/

echo -e "."

set +o history
