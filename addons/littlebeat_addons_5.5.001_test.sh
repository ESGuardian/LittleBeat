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

    if [ ! -e "$instal_dir/wazuh_ids_installed" ]; then
        if [ ! -e "$homedir/pkgs/wazuh-manager_2.0-1xenial_amd64.deb" ]; then
            wget https://github.com/ESGuardian/LittleBeat/raw/master/pkgs/wazuh-manager_2.0-1xenial_amd64.deb
            mv wazuh-manager_2.0-1xenial_amd64.deb $homedir/pkgs/wazuh-manager_2.0-1xenial_amd64.deb
        fi
        if [ ! -e "$homedir/pkgs/wazuh-api_2.0-1xenial_amd64.deb" ]; then
            wget https://github.com/ESGuardian/LittleBeat/raw/master/pkgs/wazuh-api_2.0-1xenial_amd64.deb
            mv wazuh-api_2.0-1xenial_amd64.deb $homedir/pkgs/wazuh-api_2.0-1xenial_amd64.deb
        fi

        dpkg --install $homedir/pkgs/wazuh-manager_2.0-1xenial_amd64.deb
        usermod -a -G ossec logstash
        if [ ! -e "$instal_dir/nodejs_installed" ]; then
            curl -sL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh
            bash nodesource_setup.sh
            apt-get install nodejs
            touch $instal_dir/nodejs_installed
        fi
        dpkg --install $homedir/pkgs/wazuh-api_2.0-1xenial_amd64.deb
        echo "Необходимо настроить параметры Wazuh API."
        echo "Запомните или запишите имя юзера и пароль для соединения с API."
        echo "Вам также понадобится снйчас ввести параметры для генерации"
        echo "сертификата если вы захотите использовать SSL при соединении с API."
        echo "По умолчанию визард выбирает SSL."
        bash /var/ossec/api/scripts/configure_api.sh
        if [ ! -e "/etc/logstash/conf.d/02-wazuh.conf" ]; then
            curl -so /etc/logstash/conf.d/02-wazuh.conf https://raw.githubusercontent.com/ESGuardian/LittleBeat/master/addons/wazuh-ids/02-wazuh.conf
        fi
        if [ ! -e "/etc/logstash/templates/wazuh-elastic5-template.json" ]; then
            curl -so /etc/logstash/templates/wazuh-elastic5-template.json https://raw.githubusercontent.com/ESGuardian/LittleBeat/master/addons/wazuh-ids/wazuh-elastic5-template.json
        fi
        wget https://raw.githubusercontent.com/ESGuardian/LittleBeat/master/addons/wazuh-ids/kibana_init_config.sh
        echo "Настройка индексов Kibana"
        bash kibana_init_config.sh
        service logstash restart
        echo "Установка wazuh plugin для kibana"
        echo "Это займет некоторое время ..."
        service kibana stop
        /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp.zip
        service kibana start
        touch $instal_dir/wazuh_ids_installed
    fi
    dialog --title "LITTLEBEAT" --backtitle "Установка дополнений" --msgbox "Wazuh HostIDS (OSSEC) установлен\nПочитайте LittleBeat.wiki прежде чем начинать с ним работать" 6 70
    clear
fi

