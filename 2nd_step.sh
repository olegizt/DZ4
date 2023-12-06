#!/bin/bash

sudo lvremove -y /dev/VolGroup00/LogVol00 #удаление большого логического раздела LogVol00 используемого ранее для монтирования корня
sudo lvcreate -y -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00 #создание логического раздела LogVol00 размером 8ГБ, который будет использован далее для размещения корневого раздела
sudo mkfs.xfs /dev/VolGroup00/LogVol00 #создаём на вновь созданном разделе файловую систему
sudo mount /dev/VolGroup00/LogVol00 /mnt #монтируем новый вирт.раздел в точку mnt
sudo xfsdump -J - /dev/vg_root/lv_root | sudo xfsrestore -J - /mnt #копируем данные с текущего корневого раздела в каталог mnt

sleep 20 #пауза 20 сек на всякий случай

for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done #монтируем каталоги из списка в каталог mnt
sudo chroot /mnt/ #переходим в окружение каталога mnt как корневого
sudo grub2-mkconfig -o /boot/grub2/grub.cfg #перконфигурируем загрузчик grub
cd /boot ; for i in `ls initramfs-*img`; do sudo dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done #коррекция начальной файловой системы

sudo pvcreate /dev/sd{c,d} #создаём в рамках LVM новые физ.разделы sdc и sdd
sudo vgcreate vg_var /dev/sd{c,d} #вносим разделы  sdc и sdd в группу разделов vg_var используемую в дальнейшем для как зеркальный раздел хранящий раздел VAR
sudo lvcreate -L 950M -m1 -n lv_var vg_var #создаём зеркальный вирт.том lv_var на основе вирт.группы LVM vg_var
sudo mkfs.ext4 /dev/vg_var/lv_var #форматируем новый вирт.раздел в ФС ext4
sudo mkdir /mntvar #создаём каталог для копирования в него содержимого каталога var
sudo mount /dev/vg_var/lv_var /mntvar #монтируем новый вирт.раздел в точку mntvar
sudo cp -aR /var/* /mntvar/ #копируем содержимое каталога var в каталог mntvar
sudo mkdir /tmp/oldvar && sudo mv /var/* /tmp/oldvar #создаём каталог oldvar и переносим в него содержимое каталога var
sudo umount /mntvar #размонтируем mntvar
sudo mount /dev/vg_var/lv_var /var #монтируем вирт.раздел /dev/vg_var/lv_var в точку var
sudo echo "`sudo blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab #вносим корректировки в файл fstab для монтирования вновь созданного на зеркале каталога var в точке монтирования var

echo -e "\nДля применения сделанных изменений виртуальная машина будет перезагружена через 10 секунд. После перезагрузки запустите скрипт 3rd_step.sh из каталога /root"

sleep 10 #пауза 10 сек

sudo reboot #перезагрузка ВМ для применения сделанных изменений
