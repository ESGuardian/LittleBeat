homedir="/opt/littlebeat"
install_dir="$homedir/install"
if [ ! -e $install_dir/install_completed ]; then
    log="$install_dir/install.log" 
    errlog="$install_dir/install.err"
    rm $log >/dev/nul 2>&1
    rm $errlog >/dev/nul 2>&1
    touch $log
    touch $errlog
    echo "Пожалуйста, подождите ..."
    apt-get -y install dialog 1>>$log 2>>$errlog


    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Обновление списка пакетов ....\nУстановка обновлений системы ..." 6 70

    apt-get -y update 1>>$log 2>>$errlog
    apt-get -y upgrade 1>>$log 2>>$errlog

    # список пакетов
    packs=(python-software-properties software-properties-common unzip curl openjdk-7-jre openssl nginx apache2-utils nmap samba samba-common-bin libpam-smbpass)

    err=0


    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --gauge "Установка пакетов ..." 6 70 0 < <(

       n=${#packs[*]}; 

       i=0

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
    
    
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Установка Elasticsearch ..." 6 70
    dpkg --install $homedir/pkgs/elasticsearch-2.4.4.deb 1>>$log 2>>$errlog
    if [ $? -ne 0 ]; then
            err=1
    fi
    
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Установка Logstash ..." 6 70
    dpkg --install $homedir/pkgs/logstash-2.4.1_all.deb 1>>$log 2>>$errlog
    if [ $? -ne 0 ]; then
            err=1
    fi
    
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Установка Kibana ..." 6 70
    dpkg --install $homedir/pkgs/kibana-4.6.1-amd64.deb 1>>$log 2>>$errlog
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
    recomended_mem=$(($mem/2))
    mem="$recomended_mem"m
    claster_name="elastic"
    es_data_dir="/var/lib/elasticsearch"
    
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Конфигурируем и запускаем Elastic. Это займет примерно 30 секунд ..." 10 70 
    cp $homedir/etc/default/elasticsearch /etc/default/elasticsearch
    cp $homedir/usr/lib/systemd/system/elasticsearch.service /usr/lib/systemd/system/elasticsearch.service
    sed  -i -e "s/^ES_HEAP_SIZE=.*/ES_HEAP_SIZE=$mem/" /etc/default/elasticsearch
    
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
    echo "bootstrap.memory_lock: true" >>/etc/elasticsearch/elasticsearch.yml
    echo "path.data: $es_data_dir/1" >>/etc/elasticsearch/elasticsearch.yml
    echo "path.repo: [\"$homedir/backups\"]" >>/etc/elasticsearch/elasticsearch.yml

    mkdir $es_data_dir >/dev/nul 2>&1
    mkdir $es_data_dir/1 >/dev/nul 2>&1
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
        chown -R elasticsearch:elasticsearch /opt/littlebeat/backups
        curl -XPUT 'http://localhost:9200/_snapshot/littlebeat' -d '{
            "type": "fs",
            "settings": {
                "location": "/opt/littlebeat/backups",
                "compress": true
            }
        }' >/dev/nul 2>&1
        curl -XPOST 'localhost:9200/_snapshot/littlebeat/snapshot_kibana/_restore?pretty' >/dev/nul 2>&1
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --msgbox "Elasticsearch запустился" 6 70 
    else
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --ok-button "Печалька" --msgbox "Что-то пошло не так. Проконсультируйтесь со специалистом. esguardian@outlook.com" 6 70 
        exit 1
    fi
fi

if [ ! -e "$install_dir/net_configured" ]; then

    site_name=$(hostname -f)
    dns_ip=$(nslookup $site_name | grep Server | grep -oP "(\d+\.\d+\.\d+\.\d+)" | head -1)
    check_ip=$(nslookup $site_name | grep $site_name -A 1 | grep Address | grep -oP "(\d+\.\d+\.\d+\.\d+)")
    match_ip=$(ip a | grep "$check_ip")
    if [ "$check_ip" == "" ]; then
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --menu "Мы можем использовать в настройках имя хоста (предпочтительно) или его IP адрес. Для использования имени хоста, необходимо убедиться, что в сети работает служба DNS и она знает Ваш хост.\nОднако, при проверке настроек сети выяснилось, что адрес вашего хоста $site_name не известен серверу DNS $dns_ip.\nНеобходимо выбрать один из вариантов:" 20 70 3 \
        0 "Не использовать имя хоста, настроимся на IP адрес"\
        1 "Все нормально, запись в DNS будет внесена позже"\
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
            0)
                touch "$install_dir/net_use_ip" >/dev/nul 2>&1
                ;;            
            1)
                touch "$install_dir/net_use_dns" >/dev/nul 2>&1
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
            dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --menu "Мы можем использовать в настройках имя хоста (предпочтительно) или его IP адрес. Для использования имени хоста, необходимо убедиться, что в сети работает служба DNS и она знает Ваш хост.\nОднако, при проверке настроек сети выяснилось, что для адреса вашего хоста $site_name сервер DNS $dns_ip возвращает IP адрес $check_ip, которого нет ни на одном из сетевых интерфейсов.\nНеобходимо выбрать один из вариантов:" 20 70 3 \
            0 "Не использовать имя хоста, настроимся на IP адрес"\
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
                0)
                    touch "$install_dir/net_use_ip" >/dev/nul 2>&1
                    ;;            
                1)
                    touch "$install_dir/net_use_dns" >/dev/nul 2>&1
                    touch "$install_dir/net_configured" >/dev/nul 2>&1
                    ;;
                2)
                    clear
                    echo "Настройка отменена. Завершаем работу компьютера"
                    exec shutdown -h now
                    ;;
            esac
            
        else
            dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --menu "Мы можем использовать в настройках имя хоста (предпочтительно) или его IP адрес. Мы убедились, что в сети работает служба DNS и она знает Ваш хост.\nDNS Server: $dns_ip\nHost name: $site_name\nHost IP: $check_ip\nТем не менее Вы можете выбрать настройку адресации по IP." 20 70 2 \
            0 "Использовать DNS"\
            1 "Использовать адрес IP"\
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
                0)
                    touch "$install_dir/net_use_dns" >/dev/nul 2>&1
                    touch "$install_dir/net_configured" >/dev/nul 2>&1
                    
                    ;;            
                1)
                    touch "$install_dir/net_use_ip" >/dev/nul 2>&1
                    ;;                
            esac
        fi
        
    fi


    if [ -e "$install_dir/net_use_ip" ]; then    
        c=1
        i=1
        menu=0
        isup=0
        ar=()
        while [ $c -eq 1 ]; do
            ifname=$(ip l | grep -oP "^$i:\s(\w+)")
            if [ "$ifname" == "" ]; then
                break
            fi
            ifname=${ifname#*: }
            ifstate=$( ip l | grep "^$i:" | grep -oP "state\s(\w+)")
            ifstate=${ifstate#state }
            
            if [[ "$ifname" != "lo" ]]; then
                ifadr=$(ip a | grep "scope global $ifname" | grep -oP "(\d+\.\d+\.\d+\.\d+/)")
                ifadr=${ifadr%\/}
                
                hwadr=$(ifconfig $ifname | grep "HWaddr" | grep -oP "(\S+:\S+:\S+:\S+:\S+:\S+)")
                if [ "$ifstate" == "UP" ]; then
                    iftype=$(cat /etc/network/interfaces | grep "iface $ifname" | grep -oP "inet\s(\w+)")
                    iftype=${iftype#inet }
                    ar+=($isup "$ifname $ifstate $ifadr $iftype $hwadr")
                    ((isup+=1))
                fi      
            fi
            ((i+=1))
        done 
        if [ $isup -gt 1 ]; then
            dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --menu "Давайте выберем основной сетевой интерфейс. К этому интерфейсу мы будем подключать \"приемник\" журналов событий. А также \"обнаружитель\" компьютеров.\nСледует выбрать тот интерфейс, с которого будут доступны все компьютеры Вашей сети." 20 70 $isup "${ar[@]}" 2>/tmp/choise.$$
            response=$?
            case $response in
              0) 
                choise=`cat /tmp/choise.$$`
                choise="${ar[2*$choise+1]}"
                rm /tmp/choise.$$ 
                ;;
              1) 
                clear
                echo "Настройка отменена. Завершаем работу компьютера"
                rm "$install_dir/net_use_ip" >/dev/nul 2>&1
                exec shutdown -h now
                ;;
              255) 
                clear
                echo "Настройка отменена. Завершаем работу компьютера"
                rm "$install_dir/net_use_ip" >/dev/nul 2>&1
                exec shutdown -h now
                ;;
            esac
            
        else
            choise="${ar[1]}"
        fi
        iface_ar=($choise)
        if [ "${iface_ar[3]}" == "dhcp" ]; then

            dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --msgbox "Адрес выделен с использованием сервиса DHCP. Попросите администратора сервиса зафиксировать этот адрес ${iface_ar[2]} для интерфейса с MAC-адресом ${iface_ar[4]}. Лучше сделать это прямо сейчас. " 10 70 

        fi
        echo "${iface_ar[2]}" > "$install_dir/net_use_ip"
        touch "$install_dir/net_configured" >/dev/nul 2>&1
    fi
fi

if [ ! -e "$install_dir/ssl_configured" ]; then
    if [ -e "$install_dir/net_use_dns" ]; then
        site_name=$(hostname -f)
        san="DNS.1: $site_name"
    else
        site_name=`cat "$install_dir/net_use_ip"`
        san="IP: $site_name"
    fi
    sed  -i -e "s/^\[ v3_ca \]/\[ v3_ca \]\nsubjectAltName = $san\n/" /etc/ssl/openssl.cnf
    openssl req -new -newkey rsa:2048  -SHA256 -days 3650 -nodes -x509 -subj "/C=RU/ST=Moscow/L=Moscow/O=ESGurdian/OU=ESGuardian/CN=$site_name/emailAddress=esguardian@outlook.com" -out logstash.crt >/dev/nul 2>&1
    cp privkey.pem /etc/logstash/logstash.pem
    cp logstash.crt /etc/logstash/logstash.crt
    touch "$install_dir/ssl_configured" >/dev/nul 2>&1
fi

if [ ! -e "$install_dir/logstash_configured" ]; then
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Конфигурируем и запускаем Logstash. Это займет примерно 4 минуты ..." 10 70 
    mkdir /etc/logstash/templates >/dev/nul 2>&1
    cp $homedir/etc/logstash/templates/*  /etc/logstash/templates/
    mem=`cat "$install_dir/elastic_configured"`
    if [ $mem -lt 4000 ]; then
        sed  -i -e 's/"number_of_shards" : 1/"number_of_shards" : 5/' /etc/logstash/templates/winlogbeat.template.json
        sed  -i -e 's/"number_of_shards" : 1/"number_of_shards" : 5/' /etc/logstash/templates/metricbeat.template.json
    fi
    cp $homedir/etc/logstash/conf.d/*  /etc/logstash/conf.d/
    /bin/systemctl daemon-reload >/dev/nul 2>&1
    /bin/systemctl enable logstash.service >/dev/nul 2>&1
    /opt/logstash/bin/logstash-plugin install logstash-filter-elasticsearch 1>>$log 2>>$errlog
    /opt/logstash/bin/logstash-plugin install logstash-codec-nmap 1>>$log 2>>$errlog
    
    touch "$install_dir/logstash_configured" >/dev/nul 2>&1
fi
if [ ! -e "$install_dir/logstash_started" ]; then
    /bin/systemctl start logstash.service >/dev/nul 2>&1
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --gauge "Ждем Logstash ..." 6 70 < <(
    c=1

    while [ $c -ne 202 ]
        do
            if [ -e /var/log/logstash/logstash.log ]; then
                str=$(grep -i "Pipeline main started" /var/log/logstash/logstash.log)
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
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --msgbox "Logstash запустился" 6 70 
    else
        dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --ok-button "Печалька" --msgbox "Что-то пошло не так. Проконсультируйтесь со специалистом. esguardian@outlook.com" 6 70 
        exit 1
    fi
    touch "$install_dir/logstash_started" >/dev/nul 2>&1
fi
if [ ! -e "$install_dir/kibana_started" ]; then
    rm  /etc/nginx/sites-available/default >/dev/nul 2>&1
    cp $homedir/etc/nginx/sites-available/default /etc/nginx/sites-available/default >/dev/nul 2>&1
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
    echo 'kibana.defaultAppId: "dashboard/Main-dash"' >>/opt/kibana/config/kibana.yml
    cp $homedir/install/kibana.svg /opt/kibana/src/ui/public/images/kibana.svg
    cp $homedir/install/kibana.svg /opt/kibana/optimize/bundles/src/ui/public/images/kibana.svg
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

if [ ! -e "$install_dir/samba_configured" ]; then
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Конфигурируем общедоступную папку agents ..." 8 70 

    cp -R $homedir/agents /var/lib/
    echo "[agents]" >>/etc/samba/smb.conf
    echo "  comment = clients share" >>/etc/samba/smb.conf
    echo "  path = /var/lib/agents" >>/etc/samba/smb.conf
    echo "  guest ok = yes" >>/etc/samba/smb.conf
    echo "  browseable = yes" >>/etc/samba/smb.conf
    echo "  read only = yes" >>/etc/samba/smb.conf
    service smbd restart
    touch "$install_dir/samba_configured" >/dev/nul 2>&1
fi


if [ ! -e "$install_dir/agents_configured" ]; then    
    dialog --title "LITTLEBEAT" --backtitle "Установка и первоначальная конфигурация" --infobox "Конфигурируем агентов и помещаем их в общедоступную папку agents ..." 8 70 
    if [ -e "$install_dir/net_use_dns" ]; then
        site_name=$(hostname -f)
    else
        site_name=`cat "$install_dir/net_use_ip"`
    fi
    sed  -i -e "s/hosts: \[\]/hosts: \[\"$site_name:5044\"\]/" /var/lib/agents/x64/winlogbeat/winlogbeat.yml
    cp /etc/logstash/logstash.crt /var/lib/agents/x64/winlogbeat/logstash.crt
    sed  -i -e "s/hosts: \[\]/hosts: \[\"$site_name:5044\"\]/" /var/lib/agents/x32/winlogbeat/winlogbeat.yml
    cp /etc/logstash/logstash.crt /var/lib/agents/x32/winlogbeat/logstash.crt
    sed  -i -e "s/hosts: \[\]/hosts: \[\"$site_name:5044\"\]/" /var/lib/agents/x64/metricbeat/metricbeat.yml
    cp /etc/logstash/logstash.crt /var/lib/agents/x64/metricbeat/logstash.crt
    sed  -i -e "s/hosts: \[\]/hosts: \[\"$site_name:5044\"\]/" /var/lib/agents/x32/metricbeat/metricbeat.yml
    cp /etc/logstash/logstash.crt /var/lib/agents/x32/metricbeat/logstash.crt
    touch "$install_dir/agents_configured" >/dev/nul 2>&1
fi

# Основное меню
while true; do 
main_menu=("Настройка обзора сети" "" "Консоль ELK" "" "Дополнения" "" "Выход в Shell" "" "Перезагрузка" "" "Отключение машины" "")

dialog --title "LITTLEBEAT" --backtitle "Главная консоль" --menu " " 15 50 ${#main_menu[@]} "${main_menu[@]}" 2>/tmp/choise.$$
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
if [ "$choise" == "Настройка обзора сети" ]; then
    ($homedir/bin/nmap_config.sh)
fi
if [ "$choise" == "Дополнения" ]; then
    ($homedir/bin/addons.sh)
fi
if [ "$choise" == "Консоль ELK"  ]; then
    ($homedir/bin/elastic_console.sh)
fi

if [ "$choise" == "Выход в Shell" ]; then
    clear
    echo "Выход в OS shell. Чтобы вернуться в меню, наберите exit."
    (/bin/bash --rcfile $homedir/bin/.bashrc)
fi
if [ "$choise" == "Перезагрузка" ]; then
    clear
    echo "Перезагрузка машины"
    reboot now
fi
if [ "$choise" == "Отключение машины" ]; then
    clear
    echo "Выключение машины"
    shutdown -h now
fi

done
   
clear
