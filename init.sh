echo_title() {
    echo "==================="
    echo $1
    echo "==================="
}

mkdir ~/Tools

echo_title "Установка yay..."
cd ~/Tools
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -sric

cd ..

read -p "Что у вас (amd, intel, nvidia): "
if  [ $proc == "amd" ]
then
    opengl_driver="xf86-video-ati"
elif [ $proc == "intel" ]
then
    opengl_driver="xf86-video-intel"
else
    opengl_driver="xf86-video-nouveau"

    yay -S optimus-manager
    sudo pacman -S nvidia-settings 

    sudo systemctl enable optimus-manager.service
    sudo systemctl start optimus-manager.service
fi

sudo pacman -S $opengl_driver

sudo systemctl enable fstrim.timer
sudo fstrim -v /
if [ $? -ne 0 ]
then 
    sudo fstrim -va / 
fi 

read -p "Устанавливать дополнительное ПО, для оптимизации? (ananicy-cpp, stacer-bin) [y/n]: " is_install
if [ $is_install == "y" ]
then
    echo_title "Установка дополнительных программ для оптимизации"
    yay -S stacer-bin
    yay -S ananicy-cpp

    git clone https://aur.archlinux.org/ananicy-rules.git
    cd ananicy-rules
    makepkg -sric
    cd

    sudo systemctl enable ananicy-cpp
    sudo systemctl start ananicy-cpp
fi

echo_title "Оптимизация grub..."
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet loglevel=0 rd.systemd.show_status=auto rd.udev.log_level=0 splash rootfstype=btrfs selinux=0 raid=noautodetect noibrs noibpb no_stf_barrier tsx=on tsx_async_abort=off elevator=noop mitigations=off\"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg