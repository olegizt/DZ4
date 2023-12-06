#!/bin/bash

sudo lsblk
sleep 10

sudo lvremove -y /dev/VolGroup00/LogVol00 #удаление большого логического раздела LogVol00 используемого ранее для монтирования корня
sudo lvcreate -y -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00 #создание логического раздела LogVol00 размером 8ГБ, который будет использован далее для размещения корневого раздела
sudo mkfs.xfs /dev/VolGroup00/LogVol00 #создаём на вновь созданном разделе файловую систему
sudo mount /dev/VolGroup00/LogVol00 /mnt #монтируем новый вирт.раздел в точку mnt
sudo xfsdump -J - /dev/vg_root/lv_root | sudo xfsrestore -J - /mnt #копируем данные с текущего корневого раздела в каталог mnt

sleep 10 #пауза 10 сек на всякий случай

for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done #монтируем каталоги из списка в каталог mnt
sudo chroot /mnt/ /home/vagrant/chroot2.sh #переходим в окружение каталога mnt как корневого

echo -e "\nДля применения сделанных изменений виртуальная машина будет перезагружена через 10 секунд. \nПосле перезагрузки запустите скрипт 3rd_step.sh из домашнего каталога /home/vagrant \nПерезагрузка может продолжаться до 10ти минут!"

sleep 10 #пауза 10 сек

sudo reboot #перезагрузка ВМ для применения сделанных изменений
