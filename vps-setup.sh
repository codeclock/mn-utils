# Distributed under the MIT/X11 software license, see
# http://www.opensource.org/licenses/mit-license.php.
# Suppo Core developers, 29-01-2018

set -o history

#in the following replace: 
#OS_USER_NAME_OF_YOUR_CHOICE, RPC_USER_NAME_OF_YOUR_CHOICE, PASSWORD_OF_YOUR_CHOICE,
#YOUR_MASTERNODER_PRIVATE_KEY, IP_OF_YOUR_VPS
#with your values
NEWUSER=OS_USER_NAME_OF_YOUR_CHOICE
RPCUSER=RPC_USER_NAME_OF_YOUR_CHOICE
RPCPW=PASSWORD_OF_YOUR_CHOICE
MNPRIKEY=YOUR_MASTERNODER_PRIVATE_KEY
VPSIP=IP_OF_YOUR_VPS
#don't edit anything beyond this point

if [[ "$NEWUSER" = "OS_USER_NAME_OF_YOUR_CHOICE" ]] || [[ "$RPCUSER" = "RPC_USER_NAME_OF_YOUR_CHOICE" ]]\
 || [[ "$RPCPW" = "PASSWORD_OF_YOUR_CHOICE" ]] ; then echo "Please UPDATE the variables, before running the script!"; exit 1; fi

if [ ! -f suppod ]; then
    echo "File not found! Please make sure to upload suppod and suppo-cli to the same directory as ${0##*/}"
    exit 1
fi


useradd -m $NEWUSER
apt-get update -y
apt-get upgrade -y
apt-get install sudo git python-virtualenv -y

chmod +x suppo*
chown $NEWUSER suppo*
mv suppo* /home/$NEWUSER
sudo -i -u $NEWUSER /home/$NEWUSER/suppod --daemon

stop_suppod(){
echo -e "Waiting for suppod to finish basic setup."

sleep 30
sudo -i -u $NEWUSER /home/$NEWUSER/suppo-cli stop &>/dev/null
}
stop_suppod
while [ $? != 0 ]; do stop_suppod; done

sudo -i -u $NEWUSER echo "rpcuser=$RPCUSER" > /home/$NEWUSER/.suppocore/suppo.conf
sudo -i -u $NEWUSER echo "rpcpassword=$RPCPW" >> /home/$NEWUSER/.suppocore/suppo.conf
sudo -i -u $NEWUSER echo "rpcallowip=127.0.0.1" >> /home/$NEWUSER/.suppocore/suppo.conf
sudo -i -u $NEWUSER echo "rpcport=7778" >> /home/$NEWUSER/.suppocore/suppo.conf
sudo -i -u $NEWUSER echo "daemon=1" >> /home/$NEWUSER/.suppocore/suppo.conf
sudo -i -u $NEWUSER echo "server=1" >> /home/$NEWUSER/.suppocore/suppo.conf
sudo -i -u $NEWUSER echo "maxconnections=64" >> /home/$NEWUSER/.suppocore/suppo.conf
sudo -i -u $NEWUSER echo "masternode=1" >> /home/$NEWUSER/.suppocore/suppo.conf
sudo -i -u $NEWUSER echo "masternodeprivkey=$MNPRIKEY" >> /home/$NEWUSER/.suppocore/suppo.conf
sudo -i -u $NEWUSER echo "externalip=$VPSIP" >> /home/$NEWUSER/.suppocore/suppo.conf

sudo -i -u $NEWUSER git clone https://github.com/codeclock/sentinel.git /home/$NEWUSER/.suppocore/sentinel

cd /home/$NEWUSER/.suppocore/sentinel

sudo -u $NEWUSER virtualenv venv 
sudo -u $NEWUSER venv/bin/pip install -r requirements.txt

echo -e "Waiting for cleanup."
sleep 60
sudo -i -u $NEWUSER /home/$NEWUSER/suppod

check_sync(){
echo -e "Waiting for masternode synchronization. This can take some time."
sleep 30
sudo -i -u $NEWUSER /home/$NEWUSER/suppo-cli mnsync status | grep "MASTERNODE_SYNC_FINISHED" &>/dev/null
}
check_sync
while [ $? != 0 ]; do check_sync; done

add_cronjob(){
sudo -i -u $NEWUSER bash -c '( crontab -l ; echo "* * * * * cd /home/$USER/.suppocore/sentinel && ./venv/bin/python bin/sentinel.py 2>&1 >> sentinel-cron.log") | crontab' &>/dev/null
}
typeset -fx add_cronjob

sudo -i -u $NEWUSER crontab -l | grep -q '.suppocore/sentinel' && echo "Not adding cronjob again" || add_cronjob &>/dev/null

echo -e "Setup script completed."



set +o history
