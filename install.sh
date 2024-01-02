echo_title() {
    echo "==================="
    echo $1
    echo "==================="
}

connect_to_network() {
    while [ 1 -eq 1 ]
    do
        iwctl station wlan0 scan
        iwctl station wlan0 get-networks

        echo "==================="
        read -p "Network name: " network
        read -p "Password: " password
        echo "==================="

        if iwctl station wlan0 connect "$network" --passphrase="$password"
        then
            echo "Failed to connect to $network with password $password, form again"
        else
            echo "You are connected to the network!"
            break
        fi
    done
}

check_network() {
    if ping google.com -c1
    then 
        echo "Вы подключились к сети!"
    else 
        connect_to_network
    fi
}

umount /mnt
setfont cyr-sun16


echo_title "Разметка диска"
echo -e "Помните! Для нормальной работы системы, вам нужно создать 3 раздела (4 - если еще создадите домашний раздел):\n 1) 31Mib - Bios Boot\n2) 300-500Mib - EFI System\n 3) N Gib - Linux Filesystem \n4) (не обязательный) N Gib - Linux Filesystem"
fdisk -l
read -p "Диск: " disk
echo "Удали ненужные разделы и отформотируй в GPT"
fdisk $disk
cfdisk $disk
fdisk -l $disk


echo_title "Formating partions..."
read -p "Root раздел: " root_part
mkfs.btrfs -f $root_part

read -p "EFI System раздел: " boot_part
mkfs.fat -F 32 $boot_part

read -p "Вы создали отдельный разадел для /home? [y/n]: " is_home
if [ $is_home == "y" ]
then
    read -p "Home раздел: " home_part
    mkfs.btrfs -f $home_part
fi

read -p "Путь до монтирования boot: (если у вас UEFI Bios - /mnt/boot/EFI, иначе - /mnt/boot)" path_boot



echo_title "Подключение к сети......."
read -p "У вас кабельное соединение? [y/n]: " is_lan
if [ $is_lan == "n" ]
then
    rfkill unblock wifi
    check_network
else
    dhclient
fi

echo_title "Установка базовой системы..."
read -p "Процессор (amd, intel): " proc
read -p "Консольный редактор (по умолчанию: nano): " texteditor
read -p "Ядро (имя пакета и дополнения к нему) (Пример: linux-zen linux-zen-headers): " core

if [ $proc == "amd" ]:
then
    codes="amd-ucode"
else
    codes="iucode-tool intel-ucode"
fi

if [ -z $texteditor ]
then
    $texteditor = "nano"
fi


pacstrap -K /mnt base base-devel $core dosfstools linux-firmware btrfs-progs $texteditor $codes

echo_title "Mouting partions.."
mount $root_part /mnt

mkdir $path_boot
mount $boot_part $path_boot

if [ $is_home == "y" ]
then
    mount $home_part /mnt/home
fi

genfstab -U /mnt >> /mnt/etc/fstab

cp in-chroot.sh /mnt/in-chroot.sh
cp init.sh /mnt/init.sh


echo_title "Вход в chroot.."
echo "Запустите следующий скрипт для продолжения установки в chroot: ./in-chroot.sh"
arch-chroot /mnt

echo_title "Загружаемся в систему..."
umount -R /mnt
reboot
