#!/bin/bash
homedir="/opt/littlebeat"
install_dir="$homedir/install"
log="$install_dir/install.log" 
errlog="$install_dir/install.err"
github_url="https://raw.githubusercontent.com/ESGuardian/LittleBeat/v-6.1.001"
addons_menu=("Facebook osquery LittleBeat Addon" "")

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

    if [ ! -e "$instal_dir/osquery_addon_installed" ]; then
		cd /tmp
		if [ -e "osquery-dash.json" ]; then
			rm osquery-dash.json
		fi
        wget $github_url/addons/osquery/kibana/osquery-dash.json
		curl -XPOST 127.0.0.1:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @osquery-dash.json
		if [ -e "main-dash.json" ]; then
			rm main-dash.json
		fi
        wget $github_url/addons/osquery/kibana/main-dash.json
		curl -XPOST 127.0.0.1:5601/api/kibana/dashboards/import -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @main-dash.json
		cd /etc/logstash/conf.d
		if [ -e "03-osquery.conf" ]; then
			rm 03-osquery.conf
		fi
		wget $github_url/addons/osquery/etc/logstash/conf.d/03-osquery.conf
		cd /tmp
		service logstash restart
        touch $instal_dir/osquery_addon_installed
    fi
    dialog --title "LITTLEBEAT" --backtitle "Установка дополнений" --msgbox "Facebook osquery LittleBeat Addon установлен\nПочитайте LittleBeat.wiki прежде чем начинать с ним работать" 6 70
    clear
fi

