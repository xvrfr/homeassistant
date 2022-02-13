
# i386 Home Assistant Supervised installation


###### Atom N270 Netbook MSI Wind U100

** **

### 1. Установка Debian 11 netinst non-free

** **

**Разметка:**

_Автоматическая разметка, отдельные разделы для /, /var, /tmp, /home_


**Пользователи:**

> root: pj***r3

> nu100: 


**Оболочка и системные утилиты:**

_Снять все галочки._

**Дожидаемся окончания установки, перезагрузка.**

** **

### 2. Первый консольный вход (под root)

** **

**Подключаемся к Интернету**

_Драйвер WiFi, `wpasupplicant` и `wireless-tools` в `netinst non-free` встроены:_

Команда в консоль:

```Shell
ip a
```

Выяснили, что есть 3 интерфейса:
```
lo     - виртуальный loopback
enp1s0 - проводная сетевая, down
wlp2s0 - беспроводная сетевая, down
```

Сетевые отключены, подключаемся через провод, значит проводной интерфейс надо включить:
```
ip link set enp1s0 up
```

После включения сетевой нужно запустить DHCP-клиента:
```
dhclient enp1s0
```

Интернет через локальную сеть готов, но, чтобы он подключался автоматически после перезагрузки, необходимо дополнить файл `/etc/network/interfaces`:
```
echo "" >> /etc/network/interfaces
echo "auto enp1s0" >> /etc/network/interfaces
echo "iface enp1s0 inet dhcp" >> /etc/network/interfaces
```
Настройка Интернета через WiFi не намного сложнее:
```
wpa_passphrase "YOUR_SSID" password > /etc/wpa_supplicant.conf
cp /lib/systemd/system/wpa_supplicant.service /etc/systemd/system/
systemctl enable wpa_supplicant.service
```
И дополнить файл `/etc/network/interfaces`:
```
echo "" >> /etc/network/interfaces
echo "auto wlp2s0" >> /etc/network/interfaces
echo "iface wlp2s0 inet dhcp" >> /etc/network/interfaces
```
Далее необходимо подправить файл сервиса текстовым редактором, например, `nano`:
```
nano /etc/systemd/system/wpa_supplicant.service
```
И привести строки к такому виду:
```
ExecStart=/sbin/wpa_supplicant -u -s -c /etc/wpa_supplicant.conf -i wlp2s0
Restart=always
...
#Alias=dbus-fi.w1.wpa_supplicant1.service
```

**Настройка системы**

Необходимо установить `sudo` и `openssh-server`:
```
apt update
apt upgrade
apt install sudo acpi-support vbetool openssh-server 
```

Теперь добавим пользователя `nu100` в группу `sudo`:
```
usermod -aG sudo nu100
```

_После выполнения можно (и нужно) полноценно работать от имени пользователя `nu100` и им же подключаться удаленно в локальной сети через openssh-клиент._

Чтобы названия системных папок было на английском ("Desktop" вместо "Рабочий стол") нужно запустить удаляющую и пересоздающую команду от каждого пользователя:
```
LC_ALL=C xdg-user-dirs-update --force
```
_Однако эта команда должна выполняться после установки окружения (Gnome, KDE, Xfce и др.), чего мы в этой инструкции не делали._


**Чтобы ноутбук не засыпал при закрытии крышки**
```
echo "# /etc/systemd/logind.conf" > /etc/systemd/logind.conf
echo "[Login]" >> /etc/systemd/logind.conf
echo "HandleLidSwitch=ignore" >> /etc/systemd/logind.conf
echo "HandleLidSwitchDocked=ignore" >> /etc/systemd/logind.conf
echo "LidSwitchIgnoreInhibited=no" >> /etc/systemd/logind.conf
```

**Чтобы ноутбук гасил подсветку при закрытии крышки**
```
echo "event=button/lid.*" > /etc/acpi/events/lid-button
echo "action=/etc/acpi/lid.sh" >> /etc/acpi/events/lid-button

touch /etc/acpi/lid.sh
chmod +x /etc/acpi/lid.sh
```
```
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
```
Проверить результат (необязательно) можно командой:
```
nano /etc/acpi/lid.sh
```
** **
### 3. Установка HomeAssistant Supervised
** **
По инструкции:

https://sprut.ai/article/ustanovka-home-assistant-na-netbuki-i-starye-pk
```
sudo apt install software-properties-common python3.9 python3.9-dev python3.9-venv python3-pip libffi-dev libssl-dev
sudo apt autoremove -y 
export PATH=$PATH:/usr/sbin
```
**Установка зависимостей:**
```
sudo apt install apparmor-utils apt-transport-https avahi-daemon ca-certificates curl dbus jq network-manager socat bash 
```
```
systemctl disable ModemManager 
```
```
systemctl stop ModemManager 
```
**Установка Docker:**
```
sudo apt install -y docker.io
```
**Установка HomeAssistant OS Agent:**
```
sudo apt install wget unzip udisks2
wget https://github.com/home-assistant/os-agent/releases/download/1.2.2/os-agent_1.2.2_linux_i386.deb
sudo dpkg -i os-agent_1.2.2_linux_i386.deb
```

**И, наконец, выполним приложенный модифицированный скрипт:**
```
wget https://github.com/xvrfr/homeassistant/raw/main/supervised-installer.fixed.sh
chmod 777 supervised-installer.fixed.sh
sudo /home/nu100/supervised-installer.fixed.sh
```
Если скрипт отработает без ошибок, то в конце будет показан адрес подключения.
** **
Запуск займёт минут 20.
** **
За основу брались запчасти:
```
URL_HA="https://github.com/home-assistant/cli/releases/download/4.15.1/ha_i386"    
URL_BIN_HASSIO="https://raw.githubusercontent.com/remlabm/hassio-installer/master/files/hassio-supervisor"
URL_BIN_APPARMOR="https://raw.githubusercontent.com/remlabm/hassio-installer/master/files/hassio-apparmor"
URL_SERVICE_HASSIO="https://raw.githubusercontent.com/remlabm/hassio-installer/master/files/hassio-supervisor.service"
URL_SERVICE_APPARMOR="https://raw.githubusercontent.com/remlabm/hassio-installer/master/files/hassio-apparmor.service"
```
