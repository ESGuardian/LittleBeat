#!/bin/bash
homedir="/opt/littlebeat"
install_dir="$homedir/install"
log="$install_dir/install.log" 
errlog="$install_dir/install.err"
addons_menu=("Facebook osquery Littlebeat Addon" "")

dialog --title "LITTLEBEAT" --backtitle "Выбор дополнений для установки" --menu " " 15 50 ${#addons_menu[@]} "${addons_menu[@]}" 2>/tmp/choise.$$
response=$?
case $response in
  0) 
    choise=`cat /tmp/choise.$$`
    rm /tmp/choise.$$ 
    ;;
  1) 
    choise=""
    ;;
  255) 
    choise=""
    ;;
esac
if [ "$choise" == "Facebook osquery Littlebeat Addon" ]; then
    clear
    # Установка Facebook osquery Littlebeat Addon

    if [ ! -e "$instal_dir/osquery_v1_installed" ]; then
		cd /tmp
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
		su postgres -c "psql -f create_db.sql"
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
		# pip install virtualenv
		# virtualenv env
		# source env/bin/activate
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
		# su doorman -c 'cd /opt/doorman; source env/bin/activate; python manage.py db upgrade'
		su doorman -c 'cd /opt/doorman; python manage.py db upgrade'
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
		cd /var/www/html/doorman
		# wget $github_url/addons/doorman/var/www/html/doorman/osquery.flags
		# wget $github_url/addons/doorman/var/www/html/doorman/osquery.key
		cp /etc/logstash/logstash.crt /var/www/html/doorman/logstash.crt
		cd /tmp

		usermod -G www-data -a doorman
		chown doorman:doorman -R /opt/doorman
		systemctl enable doorman
		systemctl start doorman
		service nginx restart
		wget $github_url/addons/doorman/osquery-dash.json
		curl -XPOST 127.0.0.1:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @osquery-dash.json
		cd /etc/logstash/templates
		wget $github_url/addons/doorman/etc/logstash/templates/osquery-6.1.3-template.json
		cd /etc/logstash/conf.d
		wget $github_url/addons/doorman/etc/logstash/conf.d/03-osquery.conf
		service logstash restart
        touch $instal_dir/osquery_v1_installed
    fi
    dialog --title "LITTLEBEAT" --backtitle "Установка дополнений" --msgbox "Facebook osquery Littlebeat Addon установлен\nПочитайте LittleBeat.wiki прежде чем начинать с ним работать" 6 70
    clear
fi

