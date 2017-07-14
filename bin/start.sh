pswd=$(whiptail --title "LITTLEBEAT" --backtitle "Запрос привилегий sudo"  --clear --nocancel --passwordbox "Для продолжения введите пароль для sudo" 8 70 3>&1 1>&2 2>&3)
clear
echo "$pswd" | sudo -S /opt/littlebeat/bin/main.sh
exit

