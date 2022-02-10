# homeassistant
i386 homeassistant installation

1. Установка Debian 11 netinst non-free
Автоматическая разметка, отдельные разделы для /, /var, /tmp, /home

Пользователи:
root: pjctskr3
nu100: <пробел>

Оболочка и системные утилиты:
Снять все галочки.

Установка, перезагрузка.


2. Первый консольный вход (под root)

Подключаемся к Интернету
Через локальную сеть, хотя впрочем драйвер WiFi, wpasupplicant и wireless-tools в netinst non-free встроены:

Команда в консоль:
ip a

Выяснили, что есть 3 интерфейса:
lo - виртуальный
enp1s0 - проводная сетевая, down
wlp2s0 - беспроводная сетевая, down

Сетевые отключены, их надо включить:
ip link set enp1s0 up

После включения сетевой нужно запустить DHCP-клиента:
dhclient enp1s0

Интернет через локальную сеть готов, но чтобы он подключался автоматически после перезагрузки, необходимо дополнить файл /etc/network/interfaces:

echo "" >> /etc/network/interfaces
echo "auto enp1s0" >> /etc/network/interfaces
echo "iface enp1s0 inet dhcp" >> /etc/network/interfaces

Настройка Интернета через WiFi не намного сложнее:

wpa_passphrase "XVR_WiFi" pjctskr3 > /etc/wpa_supplicant.conf
cp /lib/systemd/system/wpa_supplicant.service /etc/systemd/system/
systemctl enable wpa_supplicant.service

echo "" >> /etc/network/interfaces
echo "auto wlp2s0" >> /etc/network/interfaces
echo "iface wlp2s0 inet dhcp" >> /etc/network/interfaces

nano /etc/systemd/system/wpa_supplicant.service

И привести строки к такому виду:

ExecStart=/sbin/wpa_supplicant -u -s -c /etc/wpa_supplicant.conf -i wlp2s0
Restart=always

#Alias=dbus-fi.w1.wpa_supplicant1.service


Настройка системы
Необходимо установить sudo и openssh-server:
apt update
apt upgrade
apt install sudo acpi-support vbetool openssh-server 

Теперь добавим пользователя nu100 в группу sudo:
usermod -aG sudo nu100

После выполнения можно (и нужно) полноценно работать от имени пользователя nu100 и им же подключаться удаленно в локальной сети через openssh-клиент.

Чтобы названия системных папок было на английском ("Desktop" вместо "Работчий стол") нужно запустить удаляющую и пересоздающую команду от каждого пользователя:
LC_ALL=C xdg-user-dirs-update --force

Однако эта команда должна выполняться после установки окружения (Gnome, KDE, Xfce и др.), чего мы в этой инструкции не делали.

Чтобы ноутбук не засыпал при закрытии крышки

echo "# /etc/systemd/logind.conf" > /etc/systemd/logind.conf
echo "[Login]" >> /etc/systemd/logind.conf
echo "HandleLidSwitch=ignore" >> /etc/systemd/logind.conf
echo "HandleLidSwitchDocked=ignore" >> /etc/systemd/logind.conf
echo "LidSwitchIgnoreInhibited=no" >> /etc/systemd/logind.conf

Чтобы ноутбук гасил подсветку при закрытии крышки

echo "event=button/lid.*" > /etc/acpi/events/lid-button
echo "action=/etc/acpi/lid.sh" >> /etc/acpi/events/lid-button
touch /etc/acpi/lid.sh
chmod +x /etc/acpi/lid.sh
echo '#!/bin/bash' >  /etc/acpi/lid.sh
echo "" >> /etc/acpi/lid.sh
echo "grep -q close /proc/acpi/button/lid/*/state" >> /etc/acpi/lid.sh
echo "" >> /etc/acpi/lid.sh
echo "if [ $? = 0 ]; then" >> /etc/acpi/lid.sh
echo "    sleep 0.2" >> /etc/acpi/lid.sh
echo "echo \"vbetool dpms off\"" >> /etc/acpi/lid.sh
echo "fi" >> /etc/acpi/lid.sh
echo "" >> /etc/acpi/lid.sh
echo "grep -q open /proc/acpi/button/lid/*/state" >> /etc/acpi/lid.sh
echo "" >> /etc/acpi/lid.sh
echo "if [ $? = 0 ]; then" >> /etc/acpi/lid.sh
echo "    vbetool dpms on" >> /etc/acpi/lid.sh
echo "fi" >> /etc/acpi/lid.sh

nano /etc/acpi/lid.sh

3. Установка и базовая настройка HomeAssistant

По инструкции:
https://sprut.ai/article/ustanovka-home-assistant-na-netbuki-i-starye-pk

sudo apt install software-properties-common python3.9 python3.9-dev python3.9-venv python3-pip libffi-dev libssl-dev
sudo apt autoremove -y 
export PATH=$PATH:/usr/sbin

sudo apt install apparmor-utils apt-transport-https avahi-daemon ca-certificates curl dbus jq network-manager socat bash 
systemctl disable ModemManager 
systemctl stop ModemManager 

sudo apt install -y docker.io

И выполним приложенный модифицированный скрипт:

chmod 777 supervised-installer.sh
sudo /home/nu100/supervised-installer.sh
Запуск займёт минут 20.
