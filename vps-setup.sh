# Distributed under the MIT/X11 software license, see
# http://www.opensource.org/licenses/mit-license.php.
# Suppo Core developers, 29-01-2018

set -o history

#in the following replace: 
#OS_USER, USER_NAME_OF_YOUR_CHOICE, PASSWORD_OF_YOUR_CHOICE,
#YOUR_MASTERNODER_PRIVATE_KEY, IP_OF_YOUR_VPS
#with your values
NEWUSER=OS_USER
RPCUSER=USER_NAME_OF_YOUR_CHOICE
RPCPW=PASSWORD_OF_YOUR_CHOICE
MNPRIKEY=YOUR_MASTERNODER_PRIVATE_KEY
VPSIP=IP_OF_YOUR_VPS
#don't edit anything beyond this point


useradd -m $NEWUSER
apt-get update -y
apt-get upgrade -y
apt-get install sudo git python-virtualenv -y

mv suppo* /home/$NEWUSER
sudo -i -u $NEWUSER /home/$NEWUSER/suppod --daemon
sudo -i -u $NEWUSER ./suppo-cli stop

sudo -i -u $NEWUSER echo "rpcuser=$RPCUSER" > .suppocore/suppo.conf
sudo -i -u $NEWUSER echo "rpcpassword=$RPCPW" >> .suppocore/suppo.conf
sudo -i -u $NEWUSER echo "rpcallowip=127.0.0.1" >> .suppocore/suppo.conf
sudo -i -u $NEWUSER echo "rpcport=7778" >> .suppocore/suppo.conf
sudo -i -u $NEWUSER echo "daemon=1" >> .suppocore/suppo.conf
sudo -i -u $NEWUSER echo "server=1" >> .suppocore/suppo.conf
sudo -i -u $NEWUSER echo "maxconnections=64" >> .suppocore/suppo.conf
sudo -i -u $NEWUSER echo "masternode=1" >> .suppocore/suppo.conf
sudo -i -u $NEWUSER echo "masternodeprivkey=$MNPRIKEY" >> .suppocore/suppo.conf
sudo -i -u $NEWUSER echo "externalip=$VPSIP" >> .suppocore/suppo.conf

sudo -i -u $NEWUSER git clone https://github.com/codeclock/sentinel.git /home/$NEWUSER/.suppocore/sentinel

cd /home/$NEWUSER/.suppocore/sentinel

sudo -u $NEWUSER virtualenv venv 
sudo -u $NEWUSER venv/bin/pip install -r requirements.txt

sleep 10
sudo -i -u $NEWUSER ./suppod

check_sync(){
echo -e "Waiting for masternode synchronization. This can take some time."
sleep 30
sudo -i -u $NEWUSER ./suppo-cli mnsync status | grep "MASTERNODE_SYNC_FINISHED" &>/dev/null
}
check_sync
while [ $? != 0 ]; do check_sync; done

add_cronjob(){
sudo -i -u $NEWUSER bash -c '( crontab -l ; echo "* * * * * cd /home/$USER/.suppocore/sentinel && ./venv/bin/python bin/sentinel.py 2>&1 >> sentinel-cron.log") | crontab'
}
typeset -fx add_cronjob

sudo -i -u $NEWUSER crontab -l | grep -q '.suppocore/sentinel' && echo "Not adding cronjob again" || add_cronjob




set +o history
