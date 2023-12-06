#!/bin/bash

sudo lsblk
sleep 10

#Удаление LVM лог.раздела/группы/физ.раздела
sudo lvremove -y /dev/vg_root/lv_root
sudo vgremove -y /dev/vg_root
sudo pvremove -y /dev/sdb

#создаём/форматируем/монтируем лог.раздел LogVol_Home в LVM группе VolGroup00
sudo lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
sudo mkfs.xfs /dev/VolGroup00/LogVol_Home
sudo mount /dev/VolGroup00/LogVol_Home /mnt/

#копируем содержимое каталога /home/ в каталог /mnt/, удаляем исходный каталог
sudo cp -aR /home/* /mnt/
sudo rm -rf /home/*

#размонтируем лог.раздел LogVol_Home из токи /mnt и примонтируем его в точку /home
sudo umount /mnt
sudo mount /dev/VolGroup00/LogVol_Home /home/


sudo su -c "echo '`sudo blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0' >> /etc/fstab" #вносим корректировки в файл fstab для монтирования вновь созданного каталога home в точке монтирования home
sudo touch /home/file{1..20} #создаём в домашнем каталоге 20ть файлов
sudo lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home #делаем снэпшот текущего состояния домашнего каталога
sudo rm -f /home/file{11..20} #удаляем часть файлов
sudo umount /home #размонтируем каталог home
sudo lvconvert --merge /dev/VolGroup00/home_snap #восстанавливаем каталог home из снэпшота
sudo mount /dev/VolGroup00/LogVol_Home /home #монтируем каталог home
sudo ls /home #проверяем что ранее удалённые файлы восстановились из снэпшота

sudo lsblk
sleep 10

echo -e "\nЗадание закончено. Для выключения виртуальной машины используйте команду - shutdown now\n"
