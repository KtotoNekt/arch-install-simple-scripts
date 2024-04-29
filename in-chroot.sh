echo_title() {
    echo "==================="
    echo $1
    echo "==================="
}

setfont cyr-sun16

echo_title "Изменения пароля root"
passwd

echo_title "Разблокировка репозитория multilib"
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

pacman -Syu

echo_title "Базовая настройка"
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

sed -i "/en_US\.UTF-8/s/#//" /etc/locale.gen
sed -i "/ru_RU\.UTF-8/s/#//" /etc/locale.gen
locale-gen

touch /etc/vconsole.conf
echo -e "KEYMAP=ru\nFONT=cyr-sun16" > /etc/vconsole.conf

touch /etc/locale.conf
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf

read -p "Hostname: " hostname
touch /etc/hostname
echo $hostname > /etc/hostname
echo -e "\n127.0.0.1  localhost\n::1        localhost\n127.0.0.1  $hostname.localdomain  $hostname" >> /etc/hosts 

echo_title "Создание initramfs......."
mkinitcpio -P

echo_title "Создание пользователя с правами root....."
sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

read -p "Login: " username
useradd -m -G wheel "$username" 
passwd $username

echo_title "Установка grub и других пакетов...."
pacman -S grub efibootmgr networkmanager network-manager-applet dhclient dhcpcd
read -p "Вы устанавливаете систему на внешний накопитель? [y/n] " is_usb
if [ $is_usb == "n"]
then
    read -p "Диск: " disk
    grub-install $disk
else
    grub-install --bootloader-id=GRUB --removable --recheck
fi
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager

echo_title "Установка пакетов для видео ускорения"
read -p "Набор для (amd, intel, nvidia+intel): " proc
if [ $proc == "amd" ]  
then
    video_drivers="lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader"
elif [ $proc == "intel" ]
then
    video_drivers="lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader libva-media-driver xf86-video-intel"
else
    video_drivers="nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader lib32-opencl-nvidia opencl-nvidia libxnvctrl lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader libva-intel-driver xf86-video-intel"
fi

pacman -S $video_drivers

echo_title "Установка графической оболочки...."
read -p "Оболочка (xfce, gnome, kde, cinnamon, deepin, lxde, mate, enlightenment): " display_manager

pacman -S xorg xorg-server 
if [ $display_manager == "xfce" ]
then 
    pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
    systemctl enable lightdm 
elif [ $display_manager == "gnome" ]
then 
    pacman -S gnome gnome-extra gdm
    systemctl enable gdm
elif [ $display_manager == "kde" ]
then 
    pacman -S plasma plasma-wayland-session egl-wayland sddm sddm-kcm packagekit-qt5 kde-applications
    systemctl enable sddm
elif [ $display_manager == "cinnamon" ]
then 
    pacman -S cinnamon gdm
    systemctl enable gdm
elif [ $display_manager == "deepin" ]
then 
    pacman -S deepin deepin-extra lightdm lightdm-deepin-greeter
    systemctl enable lightdm
elif [ $display_manager == "enlightenment" ]
then 
    pacman -S enlightenment lightdm lightdm-gtk-greeter
    systemctl enable lightdm
elif [ $display_manager == "mate" ]
then 
    pacman -S mate mate-extra mate-panel mate-session-manager
    systemctl enable mdm
else
    pacman -S lxde-common lxsession openbox lxde lxdm
    systemctl enable lxdm
fi

exit