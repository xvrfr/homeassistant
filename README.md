
# Home Assistant Supervised installation for i386


###### on Atom N270 Netbook MSI Wind U100

[![hassio_badge](https://img.shields.io/badge/home%20assistant-%2341BDF5.svg?&style=for-the-badge&logo=home%20assistant&logoColor=white)](https://www.home-assistant.io/)

[![hass_inst_badge](https://img.shields.io/badge/HomeAssistant-Installer-blue.svg)](https://www.home-assistant.io/)

![Supports i386 Architecture](https://img.shields.io/badge/i386-yes-green.svg)
** **

Инструкция на русском языке доступна [ЗДЕСЬ: https://github.com/xvrfr/homeassistant/blob/main/README_RU.md](https://github.com/xvrfr/homeassistant/blob/main/README_RU.md)

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

Adding user `nu100` we created during installation to `sudo` group:
```
usermod -aG sudo nu100
```

_Great! Now we can (and must) use `nu100` user for system login and in remote connection credentials, e.g. ssh-client._

---

**Tweaks**

For user system folders to be named in English ("Desktop" but not "Рабочий стол") we need to execute re-creating by deleting shell command for every user:
```
LC_ALL=C xdg-user-dirs-update --force
```
_But this command is to be executed only after GUI (Gnome, KDE, Xfce и др.) being installed, something we are not going to do in this manual._

---

**🌜 For our laptop not to go sleep after closing display shell (lid):**

```
curl -sL "https://github.com/xvrfr/homeassistant/raw/main/files/system/logind.conf" > /etc/systemd/logind.conf
```
<h6><details><summary>Alternative file installation method via <code>echo</code> command
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

**🔅 For our laptop to turn off display LED after closing display shell (lid):**

```
curl -sL "https://github.com/xvrfr/homeassistant/raw/main/files/system/lid-button" > /etc/acpi/events/lid-button
```

Next step:

```
touch /etc/acpi/lid.sh
chmod +x /etc/acpi/lid.sh
```
```
curl -sL "https://github.com/xvrfr/homeassistant/raw/main/files/system/lid.sh" > /etc/acpi/lid.sh
```
<h6><details><summary>Alternative file installation method via <code>echo</code> command
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
To check file creation (optional) use command:
```
nano /etc/acpi/lid.sh
```
</details></h6>

** **
### 3. Installing HomeAssistant Supervised
** **
Originally:

https://sprut.ai/article/ustanovka-home-assistant-na-netbuki-i-starye-pk
```
sudo apt install software-properties-common python3.9 python3.9-dev python3.9-venv python3-pip libffi-dev libssl-dev
sudo apt autoremove -y 
export PATH=$PATH:/usr/sbin
```
**Getting dependencies:**
```
sudo apt install apparmor-utils apt-transport-https avahi-daemon ca-certificates curl dbus jq network-manager socat bash 
```
Disabling ModemManager
```
systemctl disable ModemManager 
```
```
systemctl stop ModemManager 
```
**Installing Docker:**
```
sudo apt install -y docker.io
```
**Installing HomeAssistant OS Agent:**
```
sudo apt install wget unzip udisks2
wget https://github.com/xvrfr/homeassistant/raw/main/os-agent_1.2.2_linux_i386.deb
sudo dpkg -i os-agent_1.2.2_linux_i386.deb
```

**And finally! Execute modified Supervised installation script:**
```
wget https://github.com/xvrfr/homeassistant/raw/main/supervised-installer.fixed.sh
chmod 777 supervised-installer.fixed.sh
sudo /home/nu100/supervised-installer.fixed.sh
```
If the script completes without errors, there will be web address to connect to HomeAssistant.
** **
**Pay attention that the first start will take about 20 minutes, be patient, please.**
** **
Many thanks to Kanga-who for the initial script.
The rest parts found:
```
URL_HA="https://github.com/home-assistant/cli/releases/download/4.15.1/ha_i386"    
URL_BIN_HASSIO="https://raw.githubusercontent.com/remlabm/hassio-installer/master/files/hassio-supervisor"
URL_BIN_APPARMOR="https://raw.githubusercontent.com/remlabm/hassio-installer/master/files/hassio-apparmor"
URL_SERVICE_HASSIO="https://raw.githubusercontent.com/remlabm/hassio-installer/master/files/hassio-supervisor.service"
URL_SERVICE_APPARMOR="https://raw.githubusercontent.com/remlabm/hassio-installer/master/files/hassio-apparmor.service"
```
