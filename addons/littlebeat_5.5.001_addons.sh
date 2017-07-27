#!/bin/bash
homedir="/opt/littlebeat"
install_dir="$homedir/install"
log="$install_dir/install.log" 
errlog="$install_dir/install.err"
addons_menu=("Wazuh HostIDS (OSSEC)" "")

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
if [ "$choise" == "Wazuh HostIDS (OSSEC)" ]; then
    clear
    # Установка Wazuh HostIDS (OSSEC)

    if [ ! -e "$install_dir/wazuh_ids_installed" ]; then
        if [ ! -e "$homedir/pkgs/wazuh-manager_2.0-1xenial_amd64.deb" ]; then
            wget https://github.com/ESGuardian/LittleBeat/raw/master/pkgs/wazuh-manager_2.0-1xenial_amd64.deb
            mv wazuh-manager_2.0-1xenial_amd64.deb $homedir/pkgs/wazuh-manager_2.0-1xenial_amd64.deb
        fi
        if [ ! -e "$homedir/pkgs/wazuh-api_2.0-1xenial_amd64.deb" ]; then
            wget https://github.com/ESGuardian/LittleBeat/raw/master/pkgs/wazuh-api_2.0-1xenial_amd64.deb
            mv wazuh-api_2.0-1xenial_amd64.deb $homedir/pkgs/wazuh-api_2.0-1xenial_amd64.deb
        fi
        if [ ! -e "$install_dir/wazuh-manager_installed" ]; then
            dpkg --install $homedir/pkgs/wazuh-manager_2.0-1xenial_amd64.deb
            usermod -a -G ossec logstash
            touch $install_dir/wazuh-manager_installed
        fi
        if [ ! -e "$install_dir/nodejs_installed" ]; then
            curl -sL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh
            bash nodesource_setup.sh
            apt-get install nodejs
            touch $install_dir/nodejs_installed
        fi
        if [ ! -e "$install_dir/wazuh-api_installed" ]; then
            dpkg --install $homedir/pkgs/wazuh-api_2.0-1xenial_amd64.deb
            touch $install_dir/wazuh-api_installed
        fi
        if [ ! -e "$install_dir/wazuh-api_configured" ]; then
            echo "Необходимо настроить параметры Wazuh API."
            echo "Запомните или запишите имя юзера и пароль для соединения с API."
            echo "Вам также понадобится снйчас ввести параметры для генерации"
            echo "сертификата если вы захотите использовать SSL при соединении с API."
            echo "По умолчанию визард выбирает SSL."
            bash /var/ossec/api/scripts/configure_api.sh
            touch $install_dir/wazuh-api_configured
        fi
        if [ ! -e "/etc/logstash/conf.d/02-wazuh.conf" ]; then
            curl -so /etc/logstash/conf.d/02-wazuh.conf https://raw.githubusercontent.com/ESGuardian/LittleBeat/master/addons/wazuh-ids/02-wazuh.conf
        fi
        if [ ! -e "/etc/logstash/templates/wazuh-elastic5-template.json" ]; then
            curl -so /etc/logstash/templates/wazuh-elastic5-template.json https://raw.githubusercontent.com/ESGuardian/LittleBeat/master/addons/wazuh-ids/wazuh-elastic5-template.json
        fi
        if [ ! -e "$install_dir/wazuh-ids-kibana_configured" ]; then
            wget https://raw.githubusercontent.com/ESGuardian/LittleBeat/master/addons/wazuh-ids/kibana_init_config.sh
            echo "Настройка индексов Kibana"
            bash kibana_init_config.sh
            service logstash restart
            echo "Установка wazuh plugin для kibana"
            echo "Это займет некоторое время ..."
            service kibana stop
            /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp.zip
            service kibana start
            touch $install_dir/wazuh-ids-kibana_configured
        fi       
        touch $install_dir/wazuh_ids_installed
    fi
    if [ ! -e "$install_dir/wazuh-openscap-installed" ]; then
        apt-get install libopenscap8 xsltproc
        touch $install_dir/wazuh-openscap-installed
    fi
    if [ ! -e "$install_dir/wazuh-ruleset-crontab-modified" ]; then
        echo "0  9	* * 7 root cd /var/ossec/bin && ./update_ruleset.py -r" >>/etc/crontab 
        touch $install_dir/wazuh-ruleset-crontab-modified
        /var/ossec/bin/update_ruleset.py -r
    fi
    dialog --title "LITTLEBEAT" --backtitle "Установка дополнений" --msgbox "Wazuh HostIDS (OSSEC) установлен\nПочитайте LittleBeat.wiki прежде чем начинать с ним работать" 6 70
    clear
fi

