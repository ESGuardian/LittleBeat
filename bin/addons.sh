#!/bin/bash
homedir="/opt/littlebeat"
dialog --title "LITTLEBEAT" --backtitle "Дополнения" --infobox "Идем за дополнениями на github" 7 70
wget https://raw.githubusercontent.com/ESGuardian/LittleBeat/v-6.1.001/addons/littlebeat_6.1.001_addons.sh >/dev/nul 2>&1
rm $homedir/addons/littlebeat_6.1.001_addons.sh >/dev/nul 2>&1
cp littlebeat_6.1.001_addons.sh $homedir/addons/littlebeat_6.1.001_addons.sh >/dev/nul 2>&1
rm littlebeat_6.1.001_addons.sh >/dev/nul 2>&1
chmod +x $homedir/addons/littlebeat_6.1.001_addons.sh >/dev/nul 2>&1
bash $homedir/addons/littlebeat_6.1.001_addons.sh

