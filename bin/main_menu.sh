# Основное меню
homedir="/opt/littlebeat"
while true; do 
main_menu=("Настройка обзора сети" "" "Консоль ELK" "" "Индекс процессов Windows" "" "Дополнения" "" "Выход в Shell" "" "Перезагрузка" "" "Отключение машины" "")

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
if [ "$choise" == "Индекс процессов Windows"  ]; then
    ($homedir/bin/win_proc.sh)
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
