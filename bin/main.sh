#!/bin/bash
if [[ $(id -u) -ne 0 ]] ; then 
  dialog --title "LITTLEBEAT" --backtitle "Недостаточно полномочий" --msgbox "Вы должны иметь полномочия root для работы с консолью" 6 70
  exit 1  
fi
homedir="/opt/littlebeat"
install_dir="$homedir/install"
mkdir $install_dir
log="$install_dir/install.log" 
errlog="$install_dir/install.err"
github_url="https://raw.githubusercontent.com/ESGuardian/LittleBeat/v-6.1.001"
if [ ! -e $install_dir/install_completed ]; then
    rm $log >/dev/nul 2>&1
    rm $errlog >/dev/nul 2>&1
    touch $log
    touch $errlog
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Обновление списка пакетов ....\nУстановка обновлений системы ..." 6 70
    apt-get -y update 1>>$log 2>>$errlog
    apt-get -y upgrade 1>>$log 2>>$errlog
    # список пакетов
    packs=(python-software-properties software-properties-common unzip curl openjdk-8-jre openssl nginx apache2-utils nmap samba samba-common-bin libpam-smbpass python-pip)

    err=0


    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --gauge "Установка общих пакетов системы ..." 6 70 0 < <(

       n=${#packs[*]}; 

       i=-1

       for f in "${packs[@]}"
       do
          PCT=$(( 100*(++i)/n ))
    cat <<EOF
XXX
$PCT
Устанавливается пакет "$f"...
XXX
EOF

       apt-get -y install $f 1>>$log 2>>$errlog
       if [ $? -ne 0 ]; then
            err=1
       fi
       done
    )
    
    
	cd $homedir/bin
	wget $github_url/bin/addons.sh 1>>$log 2>>$errlog
	wget $github_url/bin/elastic_console.sh 1>>$log 2>>$errlog
	wget $github_url/bin/main_menu.sh 1>>$log 2>>$errlog
	wget $github_url/bin/nmap_config.sh 1>>$log 2>>$errlog
	wget $github_url/bin/nmap-rep.sh 1>>$log 2>>$errlog
	wget $github_url/bin/win_proc.sh 1>>$log 2>>$errlog
	chmod +x *.sh 1>>$log 2>>$errlog
	
	
	cd /tmp
	URL="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.1.2.deb"
	wget "$URL" 2>&1 | \
	stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
	dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --gauge "Загружаем Elasticsearch" 6 70
	dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "устанавливаем Elasticsearch ..." 6 70
	dpkg -i elasticsearch-6.1.2.deb 1>>$log 2>>$errlog
	if [ $? -ne 0 ]; then
            err=1
    fi
	chown -R elasticsearch:elasticsearch /usr/share/elasticsearch    
    
    URL="https://artifacts.elastic.co/downloads/logstash/logstash-6.1.2.deb"
	wget "$URL" 2>&1 | \
	stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
	dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --gauge "Загружаем Logstash" 6 70
	dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "устанавливаем Logstash ..." 6 70
    dpkg -i logstash-6.1.2.deb 1>>$log 2>>$errlog
    if [ $? -ne 0 ]; then
            err=1
    fi
    
    URL="https://artifacts.elastic.co/downloads/kibana/kibana-6.1.2-amd64.deb"
	wget "$URL" 2>&1 | \
	stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
	dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --gauge "Загружаем Kibana" 6 70
	dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "устанавливаем Kibana ..." 6 70
    dpkg -i kibana-6.1.2-amd64.deb 1>>$log 2>>$errlog
    if [ $? -ne 0 ]; then
            err=1
    fi
    
    if [ $err -eq 0 ]; then
        dialog --title "| Протокол установки |" --backtitle "Установка и первоначальная конфигурация" --scrolltext --textbox $log 22 78
        touch $install_dir/install_completed
    else
        dialog --title "| ОШИБКИ! |" --backtitle "Установка и первоначальная конфигурация" --scrolltext --textbox $errlog 22 75
        shutdown -h now
    fi    

fi

if [ ! -e "$install_dir/elastic_configured" ]; then
    mem=$(free -m | grep -i mem | grep -oP '(\d+)' | head -1)
    if [ "$mem" == "" ]; then
        mem=$(free -m | grep -i память | grep -oP '(\d+)' | head -1)
    fi
    recomended_mem=$(($mem/2))
    mem="$recomended_mem"m
    claster_name="elastic"
    es_data_dir="/var/lib/elasticsearch"
    
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Конфигурируем и запускаем Elastic. Это займет примерно 30 секунд ..." 10 70 
    sed  -i -e "s/^LimitNOFILE=*/LimitNOFILE=500000/" /usr/lib/systemd/system/elasticsearch.service
    
    if [ ! -e "$install_dir/elastic_system_configured" ]; then
        echo "elasticsearch soft memlock unlimited" >>/etc/security/limits.conf
        echo "elasticsearch hard memlock unlimited" >>/etc/security/limits.conf
        echo "elasticsearch soft nofile 500000" >>/etc/security/limits.conf
        echo "elasticsearch hard nofile 500000" >>/etc/security/limits.conf

        touch "$install_dir/elastic_system_configured" >/dev/nul 2>&1
    fi
    rm /etc/elasticsearch/elasticsearch.yml
    echo "cluster.name: $claster_name" >>/etc/elasticsearch/elasticsearch.yml
    echo "cluster.routing.allocation.node_initial_primaries_recoveries: 10" >>/etc/elasticsearch/elasticsearch.yml
    echo "node.name: node-1" >>/etc/elasticsearch/elasticsearch.yml
    echo "path.data: $es_data_dir/1" >>/etc/elasticsearch/elasticsearch.yml
    echo "path.repo: [\"$homedir/backups\"]" >>/etc/elasticsearch/elasticsearch.yml
    sed  -i -e "s/^-Xms.*/-Xms$mem/" /etc/elasticsearch/jvm.options
    sed  -i -e "s/^-Xmx.*/-Xmx$mem/" /etc/elasticsearch/jvm.options

    mkdir $es_data_dir >/dev/nul 2>&1
    mkdir $es_data_dir/1 >/dev/nul 2>&1
	mkdir $homedir/backups >/dev/nul 2>&1
    chown -R elasticsearch:elasticsearch $es_data_dir >/dev/nul 2>&1
    chown -R elasticsearch:elasticsearch $homedir/backups >/dev/nul 2>&1
    /bin/systemctl daemon-reload >/dev/nul 2>&1
    /bin/systemctl enable elasticsearch.service >/dev/nul 2>&1
    echo "$recomended_mem" >$install_dir/elastic_configured
fi

if [ ! -e "$install_dir/elastic_started" ]; then
    /bin/systemctl start elasticsearch.service >/dev/nul 2>&1

    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --gauge "Ждем Elasticsearch ..." 6 70 < <(
    c=1

    while [ $c -ne 101 ]
        do
            str=$(curl http://localhost:9200/ 2>/dev/nul | grep -i "for search")
            if [ "$str" != "" ]; then
                touch /tmp/break.$$ >/dev/nul 2>&1
                break
            fi  
            echo "XXX"
            echo $c
            echo "Ждем Elasticsearch ...$c сек"
            echo "XXX"
            ((c+=1))
            sleep 1
        done
    )
    if [ -e /tmp/break.$$ ]; then
        rm /tmp/break.$$
        touch "$install_dir/elastic_started" >/dev/nul 2>&1
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --msgbox "Elasticsearch запустился" 6 70 
        # dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Конфигурация индексов LittleBeat ..." 6 70 
        
        # chown -R elasticsearch:elasticsearch /opt/littlebeat/backups
        # curl -XPUT 'http://localhost:9200/_snapshot/littlebeat' -d '{
            # "type": "fs",
            # "settings": {
                # "location": "/opt/littlebeat/backups",
                # "compress": true
            # }
        # }' >/dev/nul 2>&1
        # curl -XPOST 'localhost:9200/_snapshot/littlebeat/snapshot_kibana/_restore?pretty' >/dev/nul 2>&1
        # curl -XPUT 'http://localhost:9200/_template/win-proc-list' -d@$homedir/etc/logstash/templates/win-proc-list-template.json 1>>$log 2>>$errlog
        # curl -XPUT 'http://localhost:9200/_template/winlogbeat' -d@$homedir/etc/logstash/templates/winlogbeat.template.json 1>>$log 2>>$errlog
		cd /tmp
        pip install pytz 1>>$log 2>>$errlog
        pip install openpyxl 1>>$log 2>>$errlog
        pip install elasticsearch 1>>$log 2>>$errlog
		mkdir $homedir/py
		cd $homedir/py
		wget $github_url/py/set_proc_list.py >/dev/nul 2>&1
		wget $github_url/py/get_proc_list.py >/dev/nul 2>&1
		wget $github_url/py/get_proc_list_full.py >/dev/nul 2>&1
		chmod +x $homedir/py/set_proc_list.py >/dev/nul 2>&1
		chmod +x $homedir/py/get_proc_list.py >/dev/nul 2>&1
		chmod +x $homedir/py/get_proc_list_full.py >/dev/nul 2>&1
		mkdir $homedir/data
		mkdir $homedir/data/dashboards
		# cd $homedir/data
		# wget $github_url/data/proc_list.txt >/dev/nul 2>&1		
		# cd $homedir/data/dashboards
		# wget $github_url/data/dashboards/win-log.json >/dev/nul 2>&1

        $homedir/py/set_proc_list.py 1>>$log 2>>$errlog
		
    else
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --ok-button "Печалька" --msgbox "Что-то пошло не так. Проконсультируйтесь со специалистом. esguardian@outlook.com" 6 70 
        exit 1
    fi
fi

if [ ! -e "$install_dir/net_configured" ]; then

    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Поиск и выбор сетевых интерфейсов ..." 6 70 
    site_name=$(hostname -f)
    dns_ip=$(nslookup $site_name | grep Server | grep -oP "(\d+\.\d+\.\d+\.\d+)" | head -1)
    check_ip=$(nslookup $site_name | grep $site_name -A 1 | grep Address | grep -oP "(\d+\.\d+\.\d+\.\d+)")
    match_ip=$(ip a | grep "$check_ip")
    if [ "$check_ip" == "" ]; then
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --menu "Агенты LittleBeat обращаются к серверу по его имени. Для использования имени хоста, необходимо убедиться, что в сети работает служба DNS и она знает Ваш хост.\nОднако, при проверке настроек сети выяснилось, что адрес вашего хоста $site_name не известен серверу DNS $dns_ip.\nНеобходимо выбрать один из вариантов:" 20 70 3 \
        0 "Все нормально, запись в DNS будет внесена позже"\
        1 "Что-то не так, давайте отменим установку, пока не разберемся"\
        2>/tmp/choise.$$
        response=$?
        
        case $response in
          0) 
            choise=`cat /tmp/choise.$$`
            rm /tmp/choise.$$ 
            ;;
          1) 
            clear
            echo "Настройка отменена. Завершаем работу компьютера"
            exec shutdown -h now
            ;;
          255) 
            clear
            echo "Настройка отменена. Завершаем работу компьютера"
            exec shutdown -h now
            ;;
        esac
      
        case $choise in          
            1)
                touch "$install_dir/net_configured" >/dev/nul 2>&1
                ;;
            2)
                clear
                echo "Настройка отменена. Завершаем работу компьютера"
                exec shutdown -h now
                ;;
        esac
       
    else 
        if [ "$match_ip" == "" ]; then
            dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --menu "Агенты LittleBeat обращаются к серверу по его имени. Для использования имени хоста, необходимо убедиться, что в сети работает служба DNS и она знает Ваш хост.\nОднако, при проверке настроек сети выяснилось, что для адреса вашего хоста $site_name сервер DNS $dns_ip возвращает IP адрес $check_ip, которого нет ни на одном из сетевых интерфейсов.\nНеобходимо выбрать один из вариантов:" 20 70 3 \
            1 "Все нормально, запись в DNS будет иправлена позже"\
            2 "Что-то не так, давайте отменим установку, пока не разберемся"\
            2>/tmp/choise.$$
            response=$?
            case $response in
              0) 
                choise=`cat /tmp/choise.$$`
                rm /tmp/choise.$$ 
                ;;
              1) 
                clear
                echo "Настройка отменена. Завершаем работу компьютера"
                exec shutdown -h now
                ;;
              255) 
                clear
                echo "Настройка отменена. Завершаем работу компьютера"
                exec shutdown -h now
                ;;
            esac 
            case $choise in        
                1)
                    touch "$install_dir/net_configured" >/dev/nul 2>&1
                    ;;
                2)
                    clear
                    echo "Настройка отменена. Завершаем работу компьютера"
                    exec shutdown -h now
                    ;;
            esac           
        
        fi
        
    fi    
fi

if [ ! -e "$install_dir/ssl_configured" ]; then
    site_name=$(hostname -f)
    san="DNS.1: $site_name"
    sed  -i -e "s/^\[ v3_ca \]/\[ v3_ca \]\nsubjectAltName = $san\n/" /etc/ssl/openssl.cnf
    openssl req -new -newkey rsa:2048  -SHA256 -days 3650 -nodes -x509 -subj "/C=RU/ST=Moscow/L=Moscow/O=ESGurdian/OU=ESGuardian/CN=$site_name/emailAddress=esguardian@outlook.com" -out logstash.crt >/dev/nul 2>&1
    cp privkey.pem /etc/logstash/logstash.pem
    cp logstash.crt /etc/logstash/logstash.crt
    touch "$install_dir/ssl_configured" >/dev/nul 2>&1
fi

if [ ! -e "$install_dir/logstash_configured" ]; then
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Конфигурируем и запускаем Logstash. Это займет примерно 4 минуты ..." 10 70 
    mkdir /etc/logstash/templates >/dev/nul 2>&1
	cd /etc/logstash/templates
	wget $github_url/etc/logstash/templates/winlogbeat.template.json >/dev/nul 2>&1
	wget $github_url/etc/logstash/templates/metricbeat.template.json >/dev/nul 2>&1
    mem=`cat "$install_dir/elastic_configured"`
    if [ $mem -lt 3000 ]; then
        sed  -i -e 's/"number_of_shards" : 1/"number_of_shards" : 2/' /etc/logstash/templates/winlogbeat.template.json
        sed  -i -e 's/"number_of_shards" : 1/"number_of_shards" : 2/' /etc/logstash/templates/metricbeat.template.json
    fi
	cd /etc/logstash/conf.d/
	wget $github_url/etc/logstash/conf.d/01-beats.conf >/dev/nul 2>&1
	wget $github_url/etc/logstash/conf.d/08-nmap.conf >/dev/nul 2>&1
    cd /tmp
    
    /bin/systemctl daemon-reload >/dev/nul 2>&1
    /bin/systemctl enable logstash.service >/dev/nul 2>&1
    /usr/share/logstash/bin/logstash-plugin install logstash-filter-elasticsearch 1>>$log 2>>$errlog
    /usr/share/logstash/bin/logstash-plugin install logstash-codec-nmap 1>>$log 2>>$errlog
    
    touch "$install_dir/logstash_configured" >/dev/nul 2>&1
fi
if [ ! -e "$install_dir/logstash_started" ]; then
    /bin/systemctl start logstash.service >/dev/nul 2>&1
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --gauge "Ждем Logstash ..." 6 70 < <(
    c=1

    while [ $c -ne 202 ]
        do
            if [ -e /var/log/logstash/logstash-plain.log ]; then
                str=$(grep -i "Pipeline main started" /var/log/logstash/logstash-plain.log)
            else
                str=""
            fi
            if [ "$str" != "" ]; then
                touch /tmp/break.$$ >/dev/nul 2>&1
                break
            fi  
            pct=$(($c/2))
            echo "XXX"
            echo $pct
            echo "Ждем Logstash ...$c сек"
            echo "XXX"
            ((c+=1))
            sleep 1
        done
    )
    if [ -e /tmp/break.$$ ]; then
        rm /tmp/break.$$
        touch "$install_dir/logstash_started" >/dev/nul 2>&1
        echo "0  */2 * * * root $homedir/bin/nmap-rep.sh" >>/etc/crontab
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --msgbox "Logstash запустился" 6 70 
    else
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --ok-button "Печалька" --msgbox "Что-то пошло не так. Проконсультируйтесь со специалистом. esguardian@outlook.com" 6 70 
        exit 1
    fi
    touch "$install_dir/logstash_started" >/dev/nul 2>&1
fi
if [ ! -e "$install_dir/kibana_started" ]; then
    rm  /etc/nginx/sites-available/default >/dev/nul 2>&1
	cd /etc/nginx/sites-available/
	wget $github_url/etc/nginx/sites-available/default >/dev/nul 2>&1
	cd /tmp
    c=1
    while [ $c -eq 1 ]
    do
        password1=$(dialog --stdout --insecure --title "Установка пароля Kibana" --backtitle "Установка и первоначальная конфигурация" --passwordbox "Задайте пароль для пользователя kibana" 8 70)
        password2=$(dialog --stdout --insecure --title "Установка пароля Kibana" --backtitle "Установка и первоначальная конфигурация" --passwordbox "Повторите пароль" 8 70)
        if [ "$password1" == "$password2" ]; then
            c=0
            htpasswd -b -c /etc/nginx/conf.d/kibana.htpasswd kibana $password1 >/dev/nul 2>&1
        fi
    done
    echo 'kibana.defaultAppId: "dashboard/Main-dash"' >>/etc/kibana/kibana.yml
	cd /usr/share/kibana/src/ui/public/images/
	rm /usr/share/kibana/src/ui/public/images/kibana.svg
	wget $github_url/data/kibana.svg >/dev/nul 2>&1
	cd /usr/share/kibana/optimize/bundles/
	rm /usr/share/kibana/optimize/bundles/0cebf3d61338c454670b1c5bdf5d6d8d.svg
	wget $github_url/data/kibana.svg >/dev/nul 2>&1
    cp kibana.svg /usr/share/kibana/optimize/bundles/0cebf3d61338c454670b1c5bdf5d6d8d.svg
	rm kibana.svg
	cd /tmp
    /bin/systemctl daemon-reload >/dev/nul 2>&1
    /bin/systemctl enable nginx.service >/dev/nul 2>&1
    /bin/systemctl start nginx.service >/dev/nul 2>&1 
    /bin/systemctl enable kibana.service >/dev/nul 2>&1
    /bin/systemctl start kibana.service >/dev/nul 2>&1
    dialog --title "LITTLEBEAT" --gauge "Ждем Kibana ..." 6 70 < <(
    c=1

    while [ $c -ne 101 ]
        do
            str=$(curl http://localhost:5601/ 2>/dev/nul | grep -i "kibana")
            if [ "$str" != "" ]; then
                touch /tmp/break.$$ >/dev/nul 2>&1
                break
            fi  
            echo "XXX"
            echo $c
            echo "Ждем Kibana ...$c сек"
            echo "XXX"
            ((c+=1))
            sleep 1
        done
    )
    if [ -e /tmp/break.$$ ]; then
        rm /tmp/break.$$
        touch "$install_dir/kibana_started" >/dev/nul 2>&1
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --msgbox "Kibana запустилась" 6 70 
    else
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --ok-button "Печалька" --msgbox "Что-то пошло не так. Проконсультируйтесь со специалистом. esguardian@outlook.com" 6 70 
        exit 1
    fi
fi

service nginx restart >/dev/nul 2>&1

#if [ ! -e "$install_dir/kibana_configured" ]; then
#    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Первоначальная конфигурация Kibana ..." 8 70
#    ($homedir/bin/kibana_init_config.sh)
#    echo "0  */2	* * * root $homedir/bin/nmap-rep.sh" >>/etc/crontab  
#       
#    touch "$install_dir/kibana_configured" >/dev/nul 2>&1
#fi

# if [ ! -e "$install_dir/samba_configured" ]; then
    # dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Конфигурируем общедоступную папку agents ..." 8 70 

    # cp -R $homedir/agents /var/lib/
    # echo "[agents]" >>/etc/samba/smb.conf
    # echo "  comment = clients share" >>/etc/samba/smb.conf
    # echo "  path = /var/lib/agents" >>/etc/samba/smb.conf
    # echo "  guest ok = yes" >>/etc/samba/smb.conf
    # echo "  browseable = yes" >>/etc/samba/smb.conf
    # echo "  read only = yes" >>/etc/samba/smb.conf
    # service smbd restart
    # touch "$install_dir/samba_configured" >/dev/nul 2>&1
# fi


# if [ ! -e "$install_dir/agents_configured" ]; then    
    # dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Конфигурируем агентов и помещаем их в общедоступную папку agents ..." 8 70 
    # if [ -e "$install_dir/net_use_dns" ]; then
        # site_name=$(hostname -f)
    # else
        # site_name=`cat "$install_dir/net_use_ip"`
    # fi
    # sed  -i -e "s/hosts: \[\]/hosts: \[\"$site_name:5044\"\]/" /var/lib/agents/x64/winlogbeat/winlogbeat.yml
    # cp /etc/logstash/logstash.crt /var/lib/agents/x64/winlogbeat/logstash.crt
    # sed  -i -e "s/hosts: \[\]/hosts: \[\"$site_name:5044\"\]/" /var/lib/agents/x32/winlogbeat/winlogbeat.yml
    # cp /etc/logstash/logstash.crt /var/lib/agents/x32/winlogbeat/logstash.crt
    # sed  -i -e "s/hosts: \[\]/hosts: \[\"$site_name:5044\"\]/" /var/lib/agents/x64/metricbeat/metricbeat.yml
    # cp /etc/logstash/logstash.crt /var/lib/agents/x64/metricbeat/logstash.crt
    # sed  -i -e "s/hosts: \[\]/hosts: \[\"$site_name:5044\"\]/" /var/lib/agents/x32/metricbeat/metricbeat.yml
    # cp /etc/logstash/logstash.crt /var/lib/agents/x32/metricbeat/logstash.crt
    # touch "$install_dir/agents_configured" >/dev/nul 2>&1
# fi

$homedir/bin/main_menu.sh
   
clear
