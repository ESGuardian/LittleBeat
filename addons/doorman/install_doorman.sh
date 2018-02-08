#!/bin/bash
########
if [[ $(id -u) -ne 0 ]] ; then 
  dialog --title "LITTLEBEAT" --backtitle "Недостаточно полномочий" --msgbox "Вы должны иметь полномочия root для работы с консолью" 6 70
  exit 1  
fi
homedir="/opt/littlebeat"
install_dir="$homedir/install"
log="$install_dir/install.log" 
errlog="$install_dir/install.err"
github_url="https://raw.githubusercontent.com/ESGuardian/LittleBeat/v-6.1.001"
############3
apt-get -y update
apt-get -y upgrade
apt-get install ntp ntpdate ntp-doc -y 
systemctl enable ntpd 
systemctl start ntpd 
ntpdate pool.ntp.org || true 

###

apt-get install postgresql postgresql-contrib -y
wget $github_url/addons/doorman/create_db.sql
su postgres -c "psql -f mySqlScript.sql"
useradd doorman
apt-get install redis-server -y
systemctl enable redis-server
systemctl start redis-server

apt-get install python-pip gcc npm postgresql-server-dev-9.5 libffi-dev -y
ln -s /usr/bin/nodejs /usr/bin/node


pip install --upgrade pip

cd /opt
git clone https://github.com/mwielgoszewski/doorman.git
cd doorman 
pip install virtualenv
virtualenv env
source env/bin/activate
pip install -r requirements.txt

export DOORMAN_ENV=prod
echo "export DOORMAN_ENV=prod" >> /etc/profile

cd /opt/doorman/doorman
rm settings.py
wget $github_url/addons/doorman/doorman/settings.py

cd ..

mkdir /var/log/doorman
chown doorman:doorman -R /var/log/doorman
chown doorman:doorman -R /opt/doorman
su doorman -c 'cd /opt/doorman; source env/bin/activate; python manage.py db upgrade'

npm install bower -g
bower --allow-root install
npm install -g less
ln -s /usr/local/bin/lessc /usr/bin/lessc
cd /etc/nginx/sites-available
rm default
wget wget $github_url/addons/doorman/etc/nginx/sites-available/default
cd /tmp
pip install uwsgi flask

cd /opt/doorman
rm doorman.ini
wget $github_url/addons/doorman/doorman.ini
cd /etc/systemd/system
wget $github_url/addons/doorman/etc/systemd/system/doorman.service
mkdir /var/www/html/doorman
cd /var/www/html/doormam
wget $github_url/addons/doorman/var/www/html/doormam/osquery.flags
wget $github_url/addons/doorman/var/www/html/doormam/osquery.key
cp /etc/logstash/logstash.crt /var/www/html/doormam/logstash.crt
cd /tmp

usermod -G www-data -a doorman
chown doorman:doorman -R /opt/doorman
systemctl enable doorman
systemctl start doorman
service nginx restart
setsebool httpd_can_network_connect 1 -P
