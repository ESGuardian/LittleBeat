#!/bin/bash
homedir="/opt/littlebeat"
install_dir="$homedir/install"
log="$install_dir/install.log" 
errlog="$install_dir/install.err"
github_url="https://raw.githubusercontent.com/ESGuardian/LittleBeat/v-6.1.001"
addons_menu=("Facebook osquery LittleBeat Addon" "" "Wazuh (OSSEC) LittleBeat Addon" "" "iTop CMDB LittleBeat Addon" "" "UEBA LittleBeat Addon (ALFA)" "")

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
if [ "$choise" == "Facebook osquery LittleBeat Addon" ]; then
    clear

    if [ ! -e "$install_dir/osquery_addon_installed" ]; then
		cd /tmp
		if [ -e "osquery-dash.json" ]; then
			rm osquery-dash.json
		fi
        wget $github_url/addons/osquery/kibana/osquery-dash.json
		curl -s -H "kbn-version: $(dpkg -l | grep kibana | awk '{print $3}')" -H 'Content-Type: application/json' -XDELETE 127.0.0.1:5601/api/saved_objects/index-pattern/winlogbeat-*
		curl -XPOST 127.0.0.1:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @osquery-dash.json
		if [ -e "main-dash.json" ]; then
			rm main-dash.json
		fi
        wget $github_url/addons/main-dash.json
		curl -s -H "kbn-version: $(dpkg -l | grep kibana | awk '{print $3}')" -H 'Content-Type: application/json' -XDELETE 127.0.0.1:5601/api/saved_objects/visualization/f24a7060-0a7b-11e8-a2ce-b9829bf5932d
		curl -XPOST 127.0.0.1:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @main-dash.json
		cd /etc/logstash/conf.d
		if [ -e "03-osquery.conf" ]; then
			rm 03-osquery.conf
		fi
		wget $github_url/addons/osquery/etc/logstash/conf.d/03-osquery.conf
		cd /tmp
		service logstash restart
        touch $install_dir/osquery_addon_installed
    fi
    dialog --title "LITTLEBEAT" --backtitle "Установка дополнений" --msgbox "Facebook osquery LittleBeat Addon установлен\nПочитайте LittleBeat.wiki прежде чем начинать с ним работать" 10 70
    clear
fi
if [ "$choise" == "Wazuh (OSSEC) LittleBeat Addon" ]; then
    clear

    if [ ! -e "$install_dir/wazuh_addon_installed" ]; then
		apt update
		apt install docker.io -y
		docker volume create ossec-data
		docker run -d --restart=always -p 1514:1514/udp -p 1515:1515/tcp -v ossec-data:/var/ossec/data --name ossec-server esguardian/ossec-docker
		chmod 711 /var/lib/docker/volumes
		cd /tmp
		if [ -e "wazuh_dash.json" ]; then
			rm wazuh_dash.json
		fi
		wget $github_url/addons/ossec/kibana/wazuh_dash.json
		curl -s -H "kbn-version: $(dpkg -l | grep kibana | awk '{print $3}')" -H 'Content-Type: application/json' -XDELETE 127.0.0.1:5601/api/saved_objects/index-pattern/wazuh-alerts-*
		curl -XPOST 127.0.0.1:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @wazuh_dash.json

		if [ -e "main-dash.json" ]; then
			rm main-dash.json
		fi
		wget $github_url/addons/main-dash.json
		curl -s -H "kbn-version: $(dpkg -l | grep kibana | awk '{print $3}')" -H 'Content-Type: application/json' -XDELETE 127.0.0.1:5601/api/saved_objects/visualization/f24a7060-0a7b-11e8-a2ce-b9829bf5932d
		curl -XPOST 127.0.0.1:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @main-dash.json
		cd /etc/logstash/templates
		if [ ! -e "/etc/logstash/templates/wazuh-elastic6-template-alerts.json" ]; then
			wget $github_url/addons/ossec/logstash/templates/wazuh-elastic6-template-alerts.json
		else
			rm /etc/logstash/templates/wazuh-elastic6-template-alerts.json
			wget $github_url/addons/ossec/logstash/templates/wazuh-elastic6-template-alerts.json
		fi
		cd /etc/logstash/conf.d
		if [ ! -e "/etc/logstash/conf.d/02-wazuh.conf" ]; then
			wget $github_url/addons/ossec/logstash/conf.d/02-wazuh.conf
		else
			rm /etc/logstash/conf.d/02-wazuh.conf
			wget $github_url/addons/ossec/logstash/conf.d/02-wazuh.conf
		fi
		service logstash restart
		if ! grep -q "update_ruleset" /etc/crontab; then
			echo '0  3   * * 2 root docker exec -it ossec-server  bash -c "cd /var/ossec/bin; ./update_ruleset -r"' >> /etc/crontab
		fi
        touch $install_dir/wazuh_addon_installed
    fi
    dialog --title "LITTLEBEAT" --backtitle "Установка дополнений" --msgbox "Wazuh (OSSEC) LittleBeat Addon установлен\nПочитайте LittleBeat.wiki прежде чем начинать с ним работать" 10 70
    clear
fi

if [ "$choise" == "iTop CMDB LittleBeat Addon" ]; then
    clear

    if [ ! -e "$install_dir/itop_addon_installed" ]; then
		apt update
		apt install docker.io -y
		docker run --restart=always -d -p 127.0.0.1:3306:3306 --name=my-itop-db -e MYSQL_DATABASE=itop -e MYSQL_USER=itop -e MYSQL_PASSWORD=itop -e MYSQL_RANDOM_ROOT_PASSWORD=yes mysql:latest
		docker run --restart=always -d -p 127.0.0.1:8081:80 --link=my-itop-db:db --name=my-itop supervisions/itop:latest
		echo 'server {' >> /etc/nginx/sites-available/default
        echo '  listen            *:81;' >> /etc/nginx/sites-available/default
        echo '  server_name       littlebeat-cmdb;' >> /etc/nginx/sites-available/default
        echo '  access_log       /var/log/nginx/cmdb-access.log;' >> /etc/nginx/sites-available/default
        echo '  # ssl                     on;' >> /etc/nginx/sites-available/default
        echo '  # ssl_certificate         /etc/logstash/logstash.crt;' >> /etc/nginx/sites-available/default
        echo '  # ssl_certificate_key     /etc/logstash/logstash.pem;' >> /etc/nginx/sites-available/default
        echo '  location / {' >> /etc/nginx/sites-available/default
        echo '        proxy_pass            http://127.0.0.1:8081/;' >> /etc/nginx/sites-available/default
        echo '        proxy_redirect        off;' >> /etc/nginx/sites-available/default
        echo '        proxy_set_header X-Real-IP $remote_addr;' >> /etc/nginx/sites-available/default
        echo '        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;' >> /etc/nginx/sites-available/default
        echo '        proxy_set_header Host $http_host;' >> /etc/nginx/sites-available/default
        echo '        proxy_pass_header Set-Cookie;' >> /etc/nginx/sites-available/default
        echo '  }' >> /etc/nginx/sites-available/default
        echo '}' >> /etc/nginx/sites-available/default
		cd /opt/littlebeat/bin
		if [ ! -e "/opt/littlebeat/bin/itop_post_conf.sh" ]; then
			wget $github_url/addons/itop/itop_post_conf.sh
		else
			rm /opt/littlebeat/bin/itop_post_conf.sh
			wget $github_url/addons/itop/itop_post_conf.sh
		fi
		chmod +x /opt/littlebeat/bin/itop_post_conf.sh
		service nginx restart
        touch $install_dir/itop_addon_installed
    fi
    dialog --title "LITTLEBEAT" --backtitle "Установка дополнений" --msgbox "iTop CMDB LittleBeat Addon установлен\nТребуется конфигурация через веб-интерфейс\nЗайдите на http://littlebeat:81/setup\nДля справки смотрите  LittleBeat.wiki" 12 70
    clear
fi
if [ "$choise" == "UEBA LittleBeat Addon (ALFA)" ]; then
    clear

    if [ ! -e "$install_dir/ueba_alfa_addon_installed" ]; then
		apt update
		apt install redis-server -y
		cd $homedir/bin
		if [ ! -e "ueba" ]; then
			mkdir ueba			
		fi
		cd ueba
		if [ -e "ueba.py" ]; then
			rm ueba.py
		fi 
		wget $github_url/addons/ueba/ueba.py
		if [ ! -e "ueba_lib" ]; then
			mkdir ueba_lib			
		fi
		cd ueba_lib
		if [ -e "__init__.py" ]; then
			rm __init__.py
		fi
		wget $github_url/addons/ueba/ueba_lib/__init__.py
		if [ -e "wlogon.py" ]; then
			rm wlogon.py
			rm margin_corrector.py
			rm garbage_collector.py
		fi
		wget $github_url/addons/ueba/ueba_lib/wlogon.py
		wget $github_url/addons/ueba/ueba_lib/margin_corrector.py
		wget $github_url/addons/ueba/ueba_lib/garbage_collector.py
		chmod -R +x $homedir/bin/ueba
		cd /lib/systemd/system
		if [ -e "littlebeat-ueba.service" ]; then
			rm littlebeat-ueba.service
		fi
		wget $github_url/addons/ueba/lib/systemd/system/littlebeat-ueba.service
		cd /tmp
		pip install IPy
		pip install iso8601utils
		pip install redis
		systemctl daemon-reload
		systemctl enable littlebeat-ueba.service
		service littlebeat-ueba start
		
		cd /tmp
		if [ -e "ueba-dash.json" ]; then
			rm ueba-dash.json
		fi
		wget $github_url/addons/ueba/kibana/ueba-dash.json
		curl -s -H "kbn-version: $(dpkg -l | grep kibana | awk '{print $3}')" -H 'Content-Type: application/json' -XDELETE 127.0.0.1:5601/api/saved_objects/index-pattern/ueba-*
		curl -XPOST 127.0.0.1:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @ueba-dash.json

		if [ -e "main-dash.json" ]; then
			rm main-dash.json
		fi
		wget $github_url/addons/main-dash.json
		curl -s -H "kbn-version: $(dpkg -l | grep kibana | awk '{print $3}')" -H 'Content-Type: application/json' -XDELETE 127.0.0.1:5601/api/saved_objects/visualization/f24a7060-0a7b-11e8-a2ce-b9829bf5932d
		curl -XPOST 127.0.0.1:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @main-dash.json
		
        touch $install_dir/ueba_alfa_addon_installed
    fi
    dialog --title "LITTLEBEAT" --backtitle "Установка дополнений" --msgbox "UEBA LittleBeat Addon (ALFA) установлен\nПочитайте LittleBeat.wiki прежде чем начинать с ним работать" 10 70
    clear
fi
