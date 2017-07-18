#!/bin/bash
elk_menu=("Статус Elastic" "" "Индексы и шарды" "" "Удалить индексы" "" "Загрузить шаблон" "" "Отключить лишние реплики" "" "Проверить конфиг Logstash" "" "Рестартовать Logstash" "")
while true; do 
dialog --title "LITTLEBEAT" --menu " " 14 50 ${#elk_menu[@]} "${elk_menu[@]}" 2>/tmp/choise.$$
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
if [ "$choise" == "Статус Elastic" ]; then
    curl -XGET 'http://localhost:9200/_cluster/stats?human&pretty' >/tmp/curl.$$ 2>/dev/nul
    dialog --title "LITTLEBEAT" --backtitle "Консоль ELK" --textbox /tmp/curl.$$ 20 78
fi
if [ "$choise" == "Индексы и шарды"  ]; then
    curl -s localhost:9200/_cat/shards?v >/tmp/curl.$$ 2>/dev/nul
    dialog --title "LITTLEBEAT" --backtitle "Консоль ELK" --textbox /tmp/curl.$$ 20 78
fi
if [ "$choise" == "Удалить индексы"  ]; then

    index_name=`dialog --stdout --title "LITTLEBEAT" --backtitle "Консоль ELK. Удалить индекс." --inputbox "Имя индекса (можно использовать паттерн *)?" 10 70`
    case $? in
    0)
        dialog --title "LITTLEBEAT" --backtitle "Консоль ELK. Удалить индекс." \
                        --yesno "Вы уверены, что хотите удалить индекс $index_name?" 8 70 2>/tmp/yesno.$$
        case $? in
        0)
            curl -XDELETE "http://localhost:9200/$index_name/" >/tmp/curl.$$ 2>/dev/nul
            dialog --title "LITTLEBEAT" --backtitle "Консоль ELK. Результат операции." --textbox /tmp/curl.$$ 10 70
        ;;
        1)
            :
        ;;
        255)
            :
        ;;
        esac
    ;;
    1)
        :
    ;;
    255)
        :
    ;;
    esac

fi
if [ "$choise" == "Загрузить шаблон" ]; then

    template=`dialog --stdout --title "LITTLEBEAT" --backtitle "Консоль ELK. Выбор файла с шаблоном" --fselect / 10 70`
    case $? in
    0)
        template_name=`dialog --stdout --title "LITTLEBEAT" --backtitle "Консоль ELK. Загрузить шаблон." --inputbox "Имя шаблона?" 8 70`
        case $? in
        0)
            curl -XPUT "http://localhost:9200/_template/$template_name" -d@$template >/tmp/curl.$$ 2>/dev/nul
            dialog --title "LITTLEBEAT" --backtitle "Консоль ELK. Результат загрузки" --textbox /tmp/curl.$$ 10 70
            
        ;;
        1)
            :
        ;;
        255)
            :
        ;;
        esac
    ;;
    1)
        :;;
    255)
        :;;
    esac

fi

if [ "$choise" == "Отключить лишние реплики"  ]; then
    curl -XPUT 'localhost:9200/_settings' -d '
    {
        "index" : {
            "number_of_replicas" : 0
        }
    }' >/dev/nul 2>/dev/nul
    dialog --title "LITTLEBEAT" --backtitle "Консоль ELK" --msgbox "Отключены резервные реплики. В нашей конфигурации они не нужны." 7 70
fi
if [ "$choise" == "Проверить конфиг Logstash" ]; then

    dialog --title "LITTLEBEAT" --backtitle "Консоль ELK. Проверка конфига Logstash" --infobox "Проверка запущена. Подождите ..." 7 70
    /usr/share/logstash/bin/logstash -t -f /etc/logstash/conf.d >/tmp/result.$$ 2>/dev/nul
    
    dialog --title "LITTLEBEAT" --backtitle "Консоль ELK. Проверка конфига Logstash" --textbox /tmp/result.$$ 18 78    

fi
if [ "$choise" == "Рестартовать Logstash" ]; then
    service logstash restart >/dev/nul 2>&1
    dialog --title "LITTLEBEAT" --backtitle "Консоль ELK" --msgbox "Logstash перезапущен." 7 70
fi

done;
