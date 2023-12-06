#!/bin/bash


sudo pvcreate /dev/sdb #создаём в рамках LVM физ.раздел sdb
sudo vgcreate vg_root /dev/sdb #вносим раздел  sdb в группу разделов vg_root используемую в дальнейшем для манипуляций с корневым разделом
sudo lvcreate -n lv_root -l +100%FREE /dev/vg_root #создаём в LVM логический раздел lv_root на базе вирт.группы vg_root передав в данный раздел всё свободное пространсто данной вирт.группы.
sudo mkfs.xfs /dev/vg_root/lv_root #создаём ФС_XFS на новом вирт разделе
sudo mount /dev/vg_root/lv_root /mnt #монтируем новый вирт.раздел в точку mnt
sudo xfsdump -J - /dev/VolGroup00/LogVol00 | sudo xfsrestore -J - /mnt #копируем данные с текущего корневого раздела в каталог mnt

sleep 10 #пауза 10 сек на всякий случай

for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done #монтируем каталоги из списка в каталог mnt
sudo chroot /mnt/ /home/vagrant/chroot.sh #переходим в окружение каталога mnt как корневого и запускаем скрипт для корректировки загрузчика

echo -e "\nДля применения сделанных изменений виртуальная машина будет перезагружена через 10 секунд. \nПосле перезагрузки запустите скрипт 2nd_step.sh из домашнего каталога /home/vagrant"

sleep 10 #пауза 10 сек

sudo reboot #перезагрузка ВМ для применения сделанных изменений
