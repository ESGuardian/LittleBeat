#!/bin/bash
#nmap -T4 -F 192.168.1.0/24 -oX - | curl -H "x-nmap-target: user-subnet" http://localhost:1080 -d @-
homedir="/opt/littlebeat"
net_conf_menu=("Добавить сеть" "" "Список сетей" "" "Запустить обзор сейчас" "")
while true; do 
    dialog --title "LITTLEBEAT" --backtitle "Настройка обзора сети. Что будем делать?" --menu "Что будем делать?" 12 50 ${#net_conf_menu[@]} "${net_conf_menu[@]}" 2>/tmp/choise.$$
    response=$?
    case $response in
      0) 
        choise=`cat /tmp/choise.$$`
        rm /tmp/choise.$$ 
        ;;
      1) 
        exit
        ;;
      255) 
        exit
        ;;
    esac

    if [ "$choise" == "Добавить сеть" ]; then
        while true; do
            dialog --title "LITTLEBEAT" --backtitle "Настройка обзора сети. Добавляем сеть." \
                --inputbox "Введите адрес сети в формате CIDR (192.168.1.10/24)\nВ качестве ip адреса укажите адрес хоста, который, по Вашему мнению, должен быть сейчас доступен (это для проверки)." \
                20 70 "" 2>/tmp/cidr.$$
                
            if [ $? -eq 0 ]; then
                cidr=`cat /tmp/cidr.$$`
                adr=${cidr%\/*}
                check=$(ping -c 2 $adr | grep "bytes from $adr")
                if [ "$check" == "" ]; then
                    dialog --title "LITTLEBEAT" --backtitle "Настройка обзора сети. Добавляем сеть." \
                        --yesno "При проверке пингом адрес $adr оказался недоступен\nВы уверены, что следует оставить эту сеть?" 20 70 2>/tmp/yesno.$$
                   
                    if [ $? -eq 1 ]; then
                        cidr=""
                    fi
                fi
                if [ "$cidr" != "" ]; then
                    name=""
                    while [ "$name" == "" ]; do
                        dialog --title "LITTLEBEAT" --backtitle "Настройка обзора сети. Добавляем сеть." \
                            --inputbox "Введите краткое название сети, например: Домашняя сеть" \
                            10 70 "" 2>/tmp/name.$$
                        name=`cat /tmp/name.$$`
                        
                    done
                    echo "nmap -T4 -F $cidr -oX - | curl -H \"x-nmap-target: $name\" http://localhost:1080 -d @-" >> $homedir/bin/nmap-rep.sh
                    dialog --title "LITTLEBEAT" --backtitle "Настройка обзора сети. Добавляем сеть." \
                        --msgbox "Сеть $cidr c меткой $name добавлена" 10 70
                    break
                fi
            fi
        done
    fi
    
    if [ "$choise" == "Список сетей" ]; then
        while true 
        do
            ip_ar=($(grep -oP "(\d+\.\d+\.\d+\.\d+/\d+)" $homedir/bin/nmap-rep.sh))
            oldIFS=$IFS
            IFS="\""
            name_ar=($(grep -oP "(x-nmap-target: .*\")" $homedir/bin/nmap-rep.sh))
            IFS=$oldIFS
            n=${#name_ar[@]}
            if [ $n -eq 0 ]; then
                dialog --title "LITTLEBEAT" --backtitle "Настройка обзора сети. Список и удаление лишних" --msgbox "Список сетей пуст. Надо сначала добавить сеть" 10 70
                break
            fi
            for ((i=0;i<$n;i++))
            do
               name_ar[$i]=${name_ar[$i]#*: }
            done
            options=()
            for ((i=0;i<$n;i++))
            do
               options+=("${ip_ar[$i]}" "${name_ar[$i]}" "off")
            done
            
            dialog --title "LITTLEBEAT" --backtitle "Настройка обзора сети. Список и удаление лишних" --checklist "Здесь можно выбрать сети для удаления" 10 70 $n "${options[@]}" 2>/tmp/nets_to_delete.$$
            if [ $? -eq 0 ]; then
                nets_to_delete=($(cat /tmp/nets_to_delete.$$))
                for str in ${nets_to_delete[@]}
                do
                    str=${str%\/*}
                    sed -i "/$str/d" $homedir/bin/nmap-rep.sh 
                done
            else
                break
            fi
        done
    fi
    
    if [ "$choise" == "Запустить обзор сейчас" ]; then
        nohup $homedir/bin/nmap-rep.sh >/dev/null 2>&1 &
        dialog --title "LITTLEBEAT" --backtitle "Настройка обзора сети. Запустить обзор сейчас." \
               --msgbox "Обзор сетей запущен в фоновом режиме" 10 70
        exit
    fi
done

