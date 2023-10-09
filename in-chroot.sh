echo_title() {
    echo "==================="
    echo $1
    echo "==================="
}

echo_title "Изменения пароля root"
passwd

echo_title "Разблокировка репозитория multilib"
sed "s/#[multilib]/[multilib] s/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist" /etc/pacman.conf > /etc/pacman.conf

pacman -Syu

echo_title "Базовая настройка"
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

sed "s/#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8 s/\#ru_RU\.UTF-8 UTF-8/ru_RU\.UTF-8 UTF-8" /etc/locale.gen > /etc/locale.gen
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
sed "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers > /etc/sudoers

read -p "Login: " username
read -p "Password: " password
useradd -d /home/koshmar -G wheel -p $password $username 


echo_title "Установка grub и других пакетов...."
pacman -S grub efibootmgr networkmanager network-manager-applet dhclient dhcpcd
read -p "Диск: " disk
grub-install $disk
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager

echo_title "Установка пакетов для видео ускорения"
read -p "Набор для (amd, intel, nvidia+intel): " proc
if $proc == "amd":
then
    video_drivers="lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader"
else if $proc == "intel"
then
    video_drivers="lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader libva-media-driver xf86-video-intel"
else
    video_drivers="nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader lib32-opencl-nvidia opencl-nvidia libxnvctrl lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader libva-intel-driver xf86-video-intel"
fi

pacman -S $video_drivers

echo_title "Установка графической оболочки...."
read -p "Оболочка (xfce, gnome, kde, cinnamon, deepin, lxde, mate, enlightenment): " display_manager

pacman -S xorg xorg-server 
if $display_manager == "xfce"
then 
    pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
    systemctl enable lightdm 
else if $display_manager == "gnome"
then 
    pacman -S gnome gnome-extra gdm
    systemctl enable gdm
else if $display_manager == "kde"
then 
    pacman -S plasma plasma-wayland-session egl-wayland sddm sddm-kcm packagekit-qt5 kde-applications
    systemctl enable sddm
else if $display_manager == "cinnamon"
then 
    pacman -S cinnamon gdm
    systemctl enable gdm
else if $display_manager == "deepin"
then 
    pacman -S deepin deepin-extra lightdm lightdm-deepin-greeter
    systemctl enable lightdm
else if $display_manager == "enlightenment"
then 
    pacman -S enlightenment lightdm lightdm-gtk-greeter
    systemctl enable lightdm
else if $display_manager == "xfce"
then 
    pacman -S mate mate-extra mate-panel mate-session-manager
    systemctl enable mdm
else
    pacman -S lxde-common lxsession openbox lxde lxdm
    systemctl enable lxdm
fi

exit