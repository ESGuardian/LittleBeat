#!/bin/bash
homedir="/opt/littlebeat"
dialog --title "LITTLEBEAT" --backtitle "Дополнения" --infobox "Идем за дополнениями на github" 7 70
wget https://raw.githubusercontent.com/ESGuardian/LittleBeat/master/addons/littlebeat_5.5.001_addons.sh
rm $homedir/addons/littlebeat_5.5.001_addons.sh>/dev/nul 2>&1
cp littlebeat_5.5.001_addons.sh $homedir/addons/littlebeat_5.5.001_addons.sh>/dev/nul 2>&1
rm littlebeat_5.5.001_addons.sh >/dev/nul 2>&1
chmod +x $homedir/addons/littlebeat_5.5.001_addons.sh >/dev/nul 2>&1
($homedir/addons/littlebeat_5.5.001_addons.sh.sh)

