#!/bin/bash
echo "Что сейчас произойдет?"
echo "Сейчас мы создадим пользователя little, установим ему UID=0"
echo "и разрешим подключаться по SSH."
echo "У этого пользователя будет специальный .bashrc, в котором"
echo "он будет запускать консоль управления LittleBeat."
echo -n "Продолжаем?"
read
adduser little
sed -i -e "s#little:x:.*#little:x:0:0:little:/home/little:/bin/bash#" /etc/passwd
sed -i -e "s/^#PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config
sed -i -e "s/^PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config
echo "Сделано."
echo "Распаковка архива ..."
tar -zxf littlebeat.tar.gz -C /
chmod -R 755 /opt/littlebeat
cp /opt/littlebeat/.bashrc /home/little/.bashrc
echo "Сделано."
echo "Еще для работы меню нам нужна утилита dialog."
echo "Сейчас мы выполним update списка пакетов и установку dialog."
echo -n "Продолжаем?"
read
apt-get update
apt-get -y install dialog
echo "Сделано."

echo "Чтобы запустить LITTLEBEAT вы должны выполнить вход"
echo "как юзер little"
echo  -n "Нажмите ENTER чтобы перезапустить машину."
read
reboot now

