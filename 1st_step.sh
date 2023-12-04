#!/bin/bash

sudo su - root #вход в консоль как суперпользователь для дальнейшего ввода комманд без использования sudo
pvcreate /dev/sdb #создаём в рамках LVM физ.раздел sdb
vgcreate vg_root /dev/sdb #вносим раздел  sdb в группу разделов vg_root используемую в дальнейшем для манипуляций с корневым разделом
lvcreate -n lv_root -l +100%FREE /dev/vg_root #создаём в LVM логический раздел lv_root на базе вирт.группы vg_root передав в данный раздел всё свободное пространсто данной вирт.группы.
mkfs.xfs /dev/vg_root/lv_root #создаём ФС_XFS на новом вирт разделе
mount /dev/vg_root/lv_root /mnt #монтируем новый вирт.раздел в точку mnt
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt #копируем данные с текущего корневого раздела в каталог mnt

sleep 20 #пауза 20 сек на всякий случай

for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done #монтируем каталоги из списка в каталог mnt
chroot /mnt/ #переходим в окружение каталога mnt как корневого
grub2-mkconfig -o /boot/grub2/grub.cfg #перконфигурируем загрузчик grub
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done #коррекция начальной файловой системы
sed -i 's/rd.lvm.lv=VolGroup00\/LogVol00/rd.lvm.lv=vg_root\/lv_root' /boot/grub2/grub.cfg #указываем загрузчику с чего загрузиться
exit #выход из окружения chroot для каталога  mnt

echo -e "Для применения сделанных изменений виртуальная машина будет перезагружена через 10 секунд. После перезагрузки запустите скрипт 2nd_step.sh из каталога /root"

sleep 10 #пауза 10 сек

reboot #перезагрузка ВМ для применения сделанных изменений
