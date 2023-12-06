#!/bin/bash

grub2-mkconfig -o /boot/grub2/grub.cfg #перконфигурируем загрузчик grub
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done #коррекция начальной файловой системы
sed -i 's:rd.lvm.lv=VolGroup00/LogVol00:rd.lvm.lv=vg_root/lv_root:' /boot/grub2/grub.cfg #указываем загрузчику с чего загрузиться
exit #выход из окружения chroot для каталога  mnt
