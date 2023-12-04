#!/bin/bash

sudo su - root #вход в консоль как суперпользователь для дальнейшего ввода комманд без использования sudo

#Удаление LVM лог.раздела/группы/физ.раздела
lvremove -y /dev/vg_root/lv_root
vgremove -y /dev/vg_root
pvremove -y /dev/sdb

#создаём/форматируем/монтируем лог.раздел LogVol_Home в LVM группе VolGroup00
lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol_Home
mount /dev/VolGroup00/LogVol_Home /mnt/

#копируем содержимое каталога /home/ в каталог /mnt/, удаляем исходный каталог
cp -aR /home/* /mnt/
rm -rf /home/*

#размонтируем лог.раздел LogVol_Home из токи /mnt и примонтируем его в точку /home
umount /mnt
mount /dev/VolGroup00/LogVol_Home /home/


echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab #вносим корректировки в файл fstab для монтирования вновь созданного каталога home в точке монтирования home
touch /home/file{1..20} #создаём в домашнем каталоге 20ть файлов
lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home #делаем снэпшот текущего состояния домашнего каталога
rm -f /home/file{11..20} #удаляем часть файлов
umount /home #размонтируем каталог home
lvconvert --merge /dev/VolGroup00/home_snap #восстанавливаем каталог home из снэпшота
mount /home #монтируем каталог home
ls /home #проверяем что ранее удалённые файлы восстановились из снэпшота

echo -e "Задание закончено. Для выключения виртуальной машины используйте команду - shutdown now/n"
