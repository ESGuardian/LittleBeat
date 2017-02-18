#! /bin/bash
elk_menu=("Статус Elastic" "" "Индексы и шарды" "" "Удалить индексы" "" "Загрузить шаблон" "" "Откличить лишние реплики" "" "Отслеживать лог Elastic" "" "Отслеживать лог Logstash" "")
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
if [ "$choise" == "Удалить индексы" ]; then
    echo ""
fi
if [ "$choise" == "Загрузить шаблон" ]; then
    echo ""
fi
if [ "$choise" == "Откличить лишние реплики"  ]; then
    curl -XPUT 'localhost:9200/_settings' -d '
    {
        "index" : {
            "number_of_replicas" : 0
        }
    }' >/dev/nul 2>/dev/nul
    dialog --title "LITTLEBEAT" --backtitle "Консоль ELK" --msgbox "Отключены резервные реплики. В нашей конфигурации они не нужны." 7 70
fi
if [ "$choise" == "Отслеживать лог Elastic" ]; then
    dialog --title "LITTLEBEAT" --backtitle "Elastic лог" --tailbox /var/log/elasticsearch/elastic.log 20 78
fi
if [ "$choise" == "Отслеживать лог Logstash" ]; then
    dialog --title "LITTLEBEAT" --backtitle "Logstash лог" --tailbox /var/log/logstash/logstash-plain.log 20 78
fi

done;
