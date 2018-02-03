#!/bin/bash
github_url="https://raw.githubusercontent.com/ESGuardian/LittleBeat/v-6.1.001"
echo "Что сейчас произойдет?"
echo "Сейчас мы создадим пользователя little, установим ему UID=0"
echo "и разрешим подключаться по SSH."
echo "У этого пользователя будет специальный .bashrc, в котором"
echo "он будет запускать консоль управления LittleBeat."
echo -n "Для продолжения нажмите ENTER"
read
adduser little
sed -i -e "s#little:x:.*#little:x:0:0:little:/home/little:/bin/bash#" /etc/passwd
sed -i -e "s/^#PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config
sed -i -e "s/^PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config
echo "Сделано."
echo "Подготовка к запуску LittleBeat ..."
mkdir /opt/littlebeat
mkdir /opt/littlebeat/bin
cd /home/little/
rm .bashrc
wget $github_url/.bashrc
chmod +x .bashrc
cd /opt/littlebeat/bin
wget $github_url/bin/main.sh
echo "Сделано."
echo "Еще для работы меню нам нужна утилита dialog."
echo "Сейчас мы выполним update списка пакетов и установку dialog."
echo -n "Для продолжения нажмите ENTER"
read
cd /tmp
apt-get update
apt-get -y install dialog
echo "Сделано."

echo "Чтобы запустить LITTLEBEAT вы должны выполнить вход"
echo "как юзер little"
echo  -n "Нажмите ENTER чтобы перезапустить машину."
read
reboot now

