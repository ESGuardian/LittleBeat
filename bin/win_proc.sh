#!/bin/bash
homedir="/opt/littlebeat"
win_proc_menu=("Выгрузить неизвестные процессы" "" "Выгрузить все процессы" "" "Загрузить список процессов" "")
while true; do 
    dialog --title "LITTLEBEAT" --backtitle "Управление индексом процессов Windows" --menu "Что будем делать?" 12 50 ${#win_proc_menu[@]} "${win_proc_menu[@]}" 2>/tmp/choise.$$
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

    if [ "$choise" == "Выгрузить неизвестные процессы" ]; then
        dais=`dialog --stdout --title "LITTLEBEAT" --backtitle "Управление индексом процессов Windows" --inputbox "За какое количество дней выгрузить обнаруженные процессы?" 7 70 "1"`
        case $? in
        0)
            dialog --title "LITTLEBEAT" --backtitle "Управление индексом процессов Windows" --infobox "Выгружаем неизвестные процессы за последние $dais дней" 7 70
            $homedir/py/get_proc_list.py $dais
            
        ;;
        1)
            :
        ;;
        255)
            :
        ;;
        esac    
    fi
    
    if [ "$choise" == "Выгрузить все процессы" ]; then
        dais=`dialog --stdout --title "LITTLEBEAT" --backtitle "Управление индексом процессов Windows" --inputbox "За какое количество дней выгрузить обнаруженные процессы?" 7 70 "1"`
        case $? in
        0)
            dialog --title "LITTLEBEAT" --backtitle "Управление индексом процессов Windows" --infobox "Выгружаем все процессы, обнаруженные за последние $dais дней" 7 70
            $homedir/py/get_proc_list_full.py $dais
            
        ;;
        1)
            :
        ;;
        255)
            :
        ;;
        esac    
    fi
    
    if [ "$choise" == "Загрузить список процессов" ]; then
        dialog --title "LITTLEBEAT" --backtitle "Управление индексом процессов Windows" --infobox "Загружаем список процессов" 7 70 
        $homedir/py/set_proc_list.py
        dialog --title "LITTLEBEAT" --backtitle "Управление индексом процессов Windows" --msgbox "Список процессов загружен" 7 70
            
    fi
done

