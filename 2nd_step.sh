#!/bin/bash

sudo su - root #вход в консоль как суперпользователь для дальнейшего ввода комманд без использования sudo
lvremove -y /dev/VolGroup00/LogVol00 #удаление большого логического раздела LogVol00 используемого ранее для монтирования корня
lvcreate -y -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00 #создание логического раздела LogVol00 размером 8ГБ, который будет использован далее для размещения корневого раздела
mkfs.xfs /dev/VolGroup00/LogVol00 #создаём на вновь созданном разделе файловую систему
mount /dev/VolGroup00/LogVol00 /mnt #монтируем новый вирт.раздел в точку mnt
xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt #копируем данные с текущего корневого раздела в каталог mnt

sleep 20 #пауза 20 сек на всякий случай

for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done #монтируем каталоги из списка в каталог mnt
chroot /mnt/ #переходим в окружение каталога mnt как корневого
grub2-mkconfig -o /boot/grub2/grub.cfg #перконфигурируем загрузчик grub
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done #коррекция начальной файловой системы

pvcreate /dev/sd{c,d} #создаём в рамках LVM новые физ.разделы sdc и sdd
vgcreate vg_var /dev/sd{c,d} #вносим разделы  sdc и sdd в группу разделов vg_var используемую в дальнейшем для как зеркальный раздел хранящий раздел VAR
lvcreate -L 950M -m1 -n lv_var vg_var #создаём зеркальный вирт.том lv_var на основе вирт.группы LVM vg_var
mkfs.ext4 /dev/vg_var/lv_var #форматируем новый вирт.раздел в ФС ext4
mkdir /mntvar #создаём каталог для копирования в него содержимого каталога var
mount /dev/vg_var/lv_var /mntvar #монтируем новый вирт.раздел в точку mntvar
cp -aR /var/* /mntvar/ #копируем содержимое каталога var в каталог mntvar
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar #создаём каталог oldvar и переносим в него содержимое каталога var
umount /mntvar #размонтируем mntvar
mount /dev/vg_var/lv_var /var #монтируем вирт.раздел /dev/vg_var/lv_var в точку var
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab #вносим корректировки в файл fstab для монтирования вновь созданного на зеркале каталога var в точке монтирования var

echo -e "Для применения сделанных изменений виртуальная машина будет перезагружена через 10 секунд. После перезагрузки запустите скрипт 3rd_step.sh из каталога /root"

sleep 10 #пауза 10 сек

reboot #перезагрузка ВМ для применения сделанных изменений
