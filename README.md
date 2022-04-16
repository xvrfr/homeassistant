
# Debian i386 Home Assistant Supervised installation


###### on Atom N270 Netbook MSI Wind U100

[![hass_inst_badge](https://img.shields.io/badge/HomeAssistant-Installer-blue.svg)](https://www.home-assistant.io/)

![Supports i386 Architecture](https://img.shields.io/badge/i386-yes-green.svg)
** **

Инструкция на русском языке доступна [ЗДЕСЬ: https://github.com/xvrfr/homeassistant/raw/main/README_RU.md](https://github.com/xvrfr/homeassistant/raw/main/README_RU.md)

---

### 1. Installing Debian 11 netinst non-free

** **

**Disk partitioning:**

_Automatic, separate partitions for /, /var, /tmp, /home_


**Users (just for reference):**

> root: pj***r3

> nu100: 


**GUI and system utilities:**

_Uncheck everything._

**Waiting for installation process to complete, reboot system.**

** **

### 2. First console login (as root)

** **

**Connecting to the Internet**

_WiFi driver, `wpasupplicant` and `wireless-tools` have already been implemented into `netinst non-free`:_

Shell command:

```Shell
ip a
```

So, now we know that there were 3 interfaces found in our system:
```
lo     - virual loopback
enp1s0 - cable LAN, down
wlp2s0 - wireless, down
```

Network interfaces are down, and as we will connect via cable LAN, we should enable it first:

```
ip link set enp1s0 up
```

After enabling LAN we have to start DHCP-client:
```
dhclient enp1s0
```

Internet via LAN is ready to go, but to have the connection persistent after reboots we need to append to `/etc/network/interfaces`:
```
echo "" >> /etc/network/interfaces
echo "auto enp1s0" >> /etc/network/interfaces
echo "iface enp1s0 inet dhcp" >> /etc/network/interfaces
```
Setting up Internet via WiFi is not as complicated in fact:
```
wpa_passphrase "YOUR_SSID" password > /etc/wpa_supplicant.conf
cp /lib/systemd/system/wpa_supplicant.service /etc/systemd/system/
systemctl enable wpa_supplicant.service
```
And append `/etc/network/interfaces` for persistence as we did it for LAN:
```
echo "" >> /etc/network/interfaces
echo "auto wlp2s0" >> /etc/network/interfaces
echo "iface wlp2s0 inet dhcp" >> /etc/network/interfaces
```
Next, we are to edit wireless service file with any file editor, e.g. `nano`:
```
nano /etc/systemd/system/wpa_supplicant.service
```
And make its part look like this:
```
ExecStart=/sbin/wpa_supplicant -u -s -c /etc/wpa_supplicant.conf -i wlp2s0
Restart=always
...
#Alias=dbus-fi.w1.wpa_supplicant1.service
```

**Advanced system setup**

We need to install `sudo` and `openssh-server`:
```
apt update
apt upgrade
apt install sudo acpi-support vbetool openssh-server 
```

Now adding user `nu100` we created during installation to `sudo` group:
```
usermod -aG sudo nu100
```

_После выполнения можно (и нужно) полноценно работать от имени пользователя `nu100` и им же подключаться удаленно в локальной сети через openssh-клиент._

Чтобы названия системных папок было на английском ("Desktop" вместо "Рабочий стол") нужно запустить удаляющую и пересоздающую команду от каждого пользователя:
```
LC_ALL=C xdg-user-dirs-update --force
```
_Однако эта команда должна выполняться после установки окружения (Gnome, KDE, Xfce и др.), чего мы в этой инструкции не делали._

---

**🌜 Чтобы ноутбук не засыпал при закрытии крышки**
```
curl -sL "https://github.com/xvrfr/homeassistant/raw/main/files/system/logind.conf" > /etc/systemd/logind.conf
```
<h6><details><summary>Альтернативный способ установки файла с помощью оператора <code>echo</code>
</summary>

```
echo "# /etc/systemd/logind.conf" > /etc/systemd/logind.conf
echo "[Login]" >> /etc/systemd/logind.conf
echo "HandleLidSwitch=ignore" >> /etc/systemd/logind.conf
echo "HandleLidSwitchDocked=ignore" >> /etc/systemd/logind.conf
echo "LidSwitchIgnoreInhibited=no" >> /etc/systemd/logind.conf
```
</details></h6>

---

**🔅 Чтобы ноутбук гасил подсветку при закрытии крышки**
```
curl -sL "https://github.com/xvrfr/homeassistant/raw/main/files/system/lid-button" > /etc/acpi/events/lid-button
```

Далее необходимо выполнить:

```
touch /etc/acpi/lid.sh
chmod +x /etc/acpi/lid.sh
```
```
curl -sL "https://github.com/xvrfr/homeassistant/raw/main/files/system/lid.sh" > /etc/acpi/lid.sh
```
<h6><details><summary>Альтернативный способ установки файлов с помощью оператора <code>echo</code>
</summary>

```
echo "event=button/lid.*" > /etc/acpi/events/lid-button
echo "action=/etc/acpi/lid.sh" >> /etc/acpi/events/lid-button
```
```
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
</details></h6>

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
wget https://github.com/xvrfr/homeassistant/raw/main/os-agent_1.2.2_linux_i386.deb
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
