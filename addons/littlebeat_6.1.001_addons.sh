#!/bin/bash
homedir="/opt/littlebeat"
install_dir="$homedir/install"
log="$install_dir/install.log" 
errlog="$install_dir/install.err"
github_url="https://raw.githubusercontent.com/ESGuardian/LittleBeat/v-6.1.001"
addons_menu=("Facebook osquery LittleBeat Addon" "" "Wazuh (OSSEC) LittleBeat Addon" "" )

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
    dialog --title "LITTLEBEAT" --backtitle "Установка дополнений" --msgbox "Facebook osquery LittleBeat Addon установлен\nПочитайте LittleBeat.wiki прежде чем начинать с ним работать" 6 70
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
		if [ ! -e "/logstash/conf.d/02-wazuh.conf" ]; then
			wget $github_url/addons/ossec/logstash/conf.d/02-wazuh.conf
		else
			rm /logstash/conf.d/02-wazuh.conf
			wget $github_url/addons/ossec/logstash/conf.d/02-wazuh.conf
		fi
		service logstash restart
		if ! grep -q "update_ruleset" /etc/crontab; then
			echo '0  3   * * 2 root docker exec -it ossec-server  bash -c "cd /var/ossec/bin; ./update_ruleset -r"' >> /etc/crontab
		fi
        touch $install_dir/wazuh_addon_installed
    fi
    dialog --title "LITTLEBEAT" --backtitle "Установка дополнений" --msgbox "Wazuh (OSSEC) LittleBeat Addon установлен\nПочитайте LittleBeat.wiki прежде чем начинать с ним работать" 6 70
    clear
fi

