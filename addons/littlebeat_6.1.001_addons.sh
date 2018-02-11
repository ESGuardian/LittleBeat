#!/bin/bash
homedir="/opt/littlebeat"
install_dir="$homedir/install"
log="$install_dir/install.log" 
errlog="$install_dir/install.err"
addons_menu=("Facebook osquery Littlebeat Addon" "")

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
if [ "$choise" == "Facebook osquery Littlebeat Addon" ]; then
    clear
    # Установка Facebook osquery Littlebeat Addon

    if [ ! -e "$instal_dir/osquery_v1_installed" ]; then
		cd /tmp
		wget https://raw.githubusercontent.com/ESGuardian/LittleBeat/v-6.1.001/addons/doorman/install_doorman.sh
		chmod +x install_doorman.sh
		bash install_doorman.sh
        touch $instal_dir/osquery_v1_installed
    fi
    dialog --title "LITTLEBEAT" --backtitle "Установка дополнений" --msgbox "Facebook osquery Littlebeat Addon установлен\nПочитайте LittleBeat.wiki прежде чем начинать с ним работать" 6 70
    clear
fi

