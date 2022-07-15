#!/bin/bash

# color codes
RESTORE='\033[0m'
BLACK='\033[00;30m'
RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
CYAN='\033[00;36m'
LIGHTGRAY='\033[00;37m'
LBLACK='\033[01;30m'
LRED='\033[01;31m'
LGREEN='\033[01;32m'
LYELLOW='\033[01;33m'
LBLUE='\033[01;34m'
LPURPLE='\033[01;35m'
LCYAN='\033[01;36m'
WHITE='\033[01;37m'
OVERWRITE='\e[1A\e[K'

FILE="ip4.txt"
CF="https://www.cloudflare.com/ips-v4"
PublicIP=$(curl -s ifconfig.me)
LocalIP='192.168.10.75'
#LocalIP=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
CAREGO='216.113.113.154'
NET='CG_Cloud'
SECONDS=0


# _header colorize the given argument with spacing
function _task {
   # if _task is called while a task was set, complete the previous
   if [[ $TASK != "" ]]; then
       printf "${OVERWRITE}${LGREEN} [✓]  ${LGREEN}${TASK}\n"
   fi
   # set new task title and print
   TASK=$1
   printf "${LCYAN} [ ]  ${TASK} \n${LRED}"
}

# _cmd performs commands with error checking
function _cmd {
   # empty conduro.log
   > conduro.log
   # hide stdout, on error we print and exit
   if eval "$1" 1> /dev/null 2> conduro.log; then
     return 0 # success
   fi
   # read error from log and add spacing
   printf "${OVERWRITE}${LRED} [X]  ${TASK}${LRED}\n"
   while read line; do
      printf "      ${line}\n"
   done < conduro.log
   printf "\n"
   # remove log file
   rm conduro.log
   # exit installation
   exit 1
}

function _Ask()
{
  if  [[ ${2} != "" ]]; then
    printf "${GREEN}${1} ${YELLOW}[${2}]: ${RESTORE}"
    read
    if [[ ${REPLY} == "" ]] ; then REPLY="${2}" ; fi
  else
    printf "${GREEN}${1}: ${RESTORE}"
    read
  fi
}

function _AskPass()
{
  local __ret="UNKNOWN"
  local __ret2=""

  while [[ ${__ret} != ${__ret2} ]]
  do
    printf "${GREEN}Password: ${RESTORE}"
    read -s __ret
    printf "$\n{GREEN}Repeat Password: ${RESTORE}"
    read -s __ret2
    echo ""
    if [[ ${__ret^^} != ${__ret2^^} ]]; then
      printf "${RED}ERROR - Passwords do not match${RESTORE}\n\n"
    fi
  done
  REPLY=${__ret}
}

function _AskYN()
{
  local __flg="N"
  while [[ ${__flg} == "N" ]]
  do
    printf "${GREEN}${1}? ${YELLOW}[${2}]: ${RESTORE}"
    read -n 1
    if [[ ${REPLY} == "" ]] ; then REPLY="$2" ; else echo " "; fi

    case ${REPLY^^} in
      [Y]* ) __flg="Y";;
      [N]* ) __flg="Y";;
      * ) printf "${RED}ERROR - Passwords do not match${RESTORE}\n\n"; __flg="N";;
    esac
  done
  REPLY=${REPLY^^}
}


clear
# print logo + information
printf "${CYAN}

  ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
  ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
  ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝
  ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗
  ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
  ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
  ██╗  ██╗ █████╗ ██████╗ ██████╗ ███████╗███╗   ██╗██╗███╗   ██╗ ██████╗
  ██║  ██║██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗  ██║██║████╗  ██║██╔════╝
  ███████║███████║██████╔╝██║  ██║█████╗  ██╔██╗ ██║██║██╔██╗ ██║██║  ███╗
  ██╔══██║██╔══██║██╔══██╗██║  ██║██╔══╝  ██║╚██╗██║██║██║╚██╗██║██║   ██║
  ██║  ██║██║  ██║██║  ██║██████╔╝███████╗██║ ╚████║██║██║ ╚████║╚██████╔╝
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝
"
printf "\n         ${YELLOW}Hardening Linux UBUNTU Servers         ${LPURPLE}Ver 1.35${RESTORE}"
printf "                                                                    ${YELLOW}by: ${LPURPLE}Martin Boni${RESTORE}\n\n\n"


# script must be run as root
if [[ $(id -u) -ne 0 ]] ; then printf "\n${LRED} Please run as root${RESTORE}\n\n" ; exit 1 ; fi
__OS=$(lsb_release -d | awk '{print $2}')
if [[ ${__OS} != "Ubuntu" ]]; then printf "\n${LRED} Unknown operating system. Script cannot run.\n\n${RESTORE}$(lsb_release -a)\n\n" ; exit 1 ; fi


_AskYN "Continue (y/n)" "Y"
if [[ ${REPLY^^} != "Y" ]] ; then exit 0 ; fi
printf "\n"
_Ask "Change ssh port" "22" && __Port=$REPLY
_AskYN "Create Martin user (y/n)" "Y" && __USR=$REPLY
_AskYN "Install NGINX Proxy Manager (y/n)" "Y" && __NGINX=$REPLY
_AskYN "Install Antivirus & Rootkit (y/n)" "Y" && __VIRUS=$REPLY
printf "\n\n"


# update OS dependencies
_task "update operating system"
   _cmd 'sudo apt-get update'
   _cmd 'sudo apt-get full-upgrade -y'


# update application dependencies
_task "update app dependencies"
   _cmd 'sudo apt-get install nano curl wget ufw sed -y'
   _cmd 'sudo apt-get full-upgrade -y'

# remove existing applications
_task "remove apps to be reinstalled"
   _cmd 'sudo apt-get purge --auto-remove lynis fail2ban -y'
   _cmd 'sudo apt update'
   _cmd 'sudo apt-get autoremove -y'
   _cmd 'sudo apt-get autoclean -y'
   printf "${OVERWRITE}"


# update shell command prompt
PRPT="\[\033[0;31m\]\342\224\214\342\224\200\[\[\033[0;39m\]\u\[\033[01;33m\]@\[\033[01;96m\]\h\[\033[0;31m\]]\342\224\200[\[\033[0;32m\]\w\[\033[0;31m\]]\n\[\033[0;31m\]\342\224\224\342\224\200\342\224\200\342\224\200 \[\033[0m\]\[\e[01;33m\]\\$\[\e[0m\]"
task "update shell command prompt"
  _cmd 'echo "PS1=\"${PRPT}\"" | sudo tee -a /etc/bash.bashrc'
  if [[ -d "/home/martin" ]]; then _cmd 'echo "PS1=\"${PRPT}\"" | sudo tee -a /home/martin/.bashrc'; fi
  if [[ ${USER} != "root" ]]; then _cmd 'echo "PS1=\"${PRPT}\"" | sudo tee -a /home/${USER}/.bashrc'; fi


# Update Nameservers
_task "update nameservers"
   _cmd 'sudo truncate -s0 /etc/resolv.conf'
   _cmd 'echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf'
   _cmd 'echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf'


# Update NTP servers
_task "update ntp servers"
   _cmd 'sudo truncate -s0 /etc/systemd/timesyncd.conf'
   _cmd 'echo "[Time]" | sudo tee -a /etc/systemd/timesyncd.conf'
   _cmd 'echo "NTP=time.cloudflare.com" | sudo tee -a /etc/systemd/timesyncd.conf'
   _cmd 'echo "FallbackNTP=ca.pool.ntp.org" | sudo tee -a /etc/systemd/timesyncd.conf'


# add martin user
GIT="https://raw.githubusercontent.com/martyb95/hardening/main"
if [[ $__USR == "Y" ]]; then
  _task "create martin user"
     if [[ -z $(id -u "martin" 2>/dev/null) ]]; then _cmd 'sudo useradd -m martin'; fi
     _cmd 'sudo usermod -a -G sudo,lxd,adm martin'
     _cmd 'mkdir -p /home/martin/.ssh'
     _cmd 'sudo wget --timeout=5 --tries=2 --quiet -O /home/martin/.ssh/authorized_keys $GIT/authorized_keys'
     _cmd 'sudo chmod 0700 /home/martin/.ssh/'
fi


# Update SSHD_CONFIG
_task "update sshd_conf"
   _cmd 'sudo wget --timeout=5 --tries=2 --quiet -O /etc/ssh/sshd_config $GIT/sshd.conf'

_task "update ssh port"
   _cmd 'echo "Port ${__Port}" | sudo tee -a /etc/ssh/sshd_config'


# Add SSH keys to user
_task "add SSH keys to users"
   if [ ${USER} != "root" ]; then
     _cmd 'mkdir -p /home/${USER}/.ssh'
     _cmd 'sudo wget --timeout=5 --tries=2 --quiet -O /home/${USER}/.ssh/authorized_keys $GIT/authorized_keys'
     _cmd 'sudo chmod 0700 /home/${USER}/.ssh/'
   fi
   printf "${OVERWRITE}"


# Install Lynis
TMP=$(lynis show version)
_task "install Lynis audit software"
   if [[ "$TMP" != "3."* ]]; then
     _cmd 'wget --timeout=5 --tries=2 --quiet -O - https://packages.cisofy.com/keys/cisofy-software-public.key | sudo apt-key add -'
     _cmd 'echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list'
   fi
   _cmd 'sudo apt-get update'
   _cmd 'sudo apt-get install lynis -y'


# Install NGINX Proxy Manager
NGX="https://raw.githubusercontent.com/ej52/proxmox-scripts/main/lxc/nginx-proxy-manager/setup.sh"
if [[ $__NGINX == "Y" ]]; then
  _task "install NGINX Proxy Manager"
     wget --no-cache -qO - ${NGX} | sudo sh >/dev/null 2>&1
     sudo rm -f setup.sh >/dev/null 2>&1
     sudo mv /var/lib/dpkg/info/install-info.postinst /var/lib/dpkg/info/install-info.postinst.bad >/dev/null 2>&1
     _cmd 'sudo apt update'
fi


# firewall
_task "configure firewall"
   _cmd 'sudo ufw disable'
   _cmd 'echo "y" | sudo ufw reset'
   _cmd 'sudo ufw logging off'
   _cmd 'sudo ufw default deny incoming'
   _cmd 'sudo ufw default allow outgoing'
   # Add rules for the CareGo public IP
   _cmd 'sudo ufw allow from ${CAREGO} to any port 3389 proto tcp comment "rdp"'
   _cmd 'sudo ufw allow from ${CAREGO} to any port ${__Port} proto tcp comment "ssh"'
   _cmd 'sudo ufw allow from ${CAREGO} to any port 81 proto tcp comment "nginxpm"'
   _cmd 'sudo ufw allow from ${CAREGO} to any port 80 proto tcp comment "HTTP"'
   _cmd 'sudo ufw allow from ${CAREGO} to any port 443 proto tcp comment "HTTPS"'
   if [ ${PublicIP} != ${CAREGO} ]; then
      # Add rules for Public IP
      _cmd 'sudo ufw allow from ${PublicIP} to any port ${__Port} proto tcp comment "ssh"'
      _cmd 'sudo ufw allow from ${PublicIP} to any port 81 proto tcp comment "nginxpm"'
      _cmd 'sudo ufw allow from ${PublicIP} to any port 80 proto tcp comment "HTTP"'
      _cmd 'sudo ufw allow from ${PublicIP} to any port 443 proto tcp comment "HTTPS"'
      # Add rules for the computer that is running the script
      _cmd 'sudo ufw allow from ${LocalIP} to any port ${__Port} proto tcp comment "ssh"'
      _cmd 'sudo ufw allow from ${LocalIP} to any port 81 proto tcp comment "nginxpm"'
      _cmd 'sudo ufw allow from ${LocalIP} to any port 80 proto tcp comment "HTTP"'
      _cmd 'sudo ufw allow from ${LocalIP} to any port 443 proto tcp comment "HTTPS"'	  
   fi
   _cmd 'sudo ufw limit ${__Port}'
   _cmd 'sudo sed -i "/ipv6=/Id" /etc/default/ufw'
   _cmd 'echo "IPV6=no" | sudo tee -a /etc/default/ufw'
   # Add rules to allow cloudflare into the VM
   if [ -f "$FILE" ]; then rm $FILE; fi
   wget --timeout=5 --tries=2 --quiet -O $FILE $CF >/dev/null 2>&1
   while read ip4; do _cmd 'sudo ufw allow from ${ip4} to any port 80 proto tcp comment "cloudflare IPs"'; done < $FILE
   while read ip4; do _cmd 'sudo ufw allow from ${ip4} to any port 443 proto tcp comment "cloudflare IPs"'; done < $FILE
   # Disable ping / ICMP to the VM
   sudo sed -i '/ufw-before-input.*icmp/s/ACCEPT/DROP/g' /etc/ufw/before.rules >/dev/null 2>&1
   sudo sed -i '/ufw-before-forward.*icmp/s/ACCEPT/DROP/g' /etc/ufw/before.rules >/dev/null 2>&1

# Install antivirus & rootkit
if [[ $__VIRUS == "Y" ]]; then
  _task "install antivirus and rootkit"
     _cmd 'sudo apt-get install chkrootkit clamav clamav-daemon -y'
	 _cmd 'sudo systemctl stop clamav-freshclam'
	 _cmd 'sudo freshclam'
	 _cmd 'sudo systemctl start clamav-freshclam'
fi


# Install Fail2Ban
_task "install Fail2Ban"
   _cmd 'sudo apt-get install fail2ban -y'
   _cmd 'sudo wget --timeout=5 --tries=2 --quiet -O /etc/fail2ban/jail.local $GIT/jail.local'


# Download and Update sysctl.conf
_task "download and update sysctl.conf"
   _cmd 'sudo wget --timeout=5 --tries=2 --quiet -c https://raw.githubusercontent.com/conduro/ubuntu/main/sysctl.conf -O /etc/sysctl.conf'
   _cmd 'sudo sysctl -p'


# disable system logging
_task "disable system logging"
  _cmd 'sudo systemctl stop systemd-journald.service'
  _cmd 'sudo systemctl disable systemd-journald.service'
  _cmd 'sudo systemctl mask systemd-journald.service'
  _cmd 'sudo systemctl stop rsyslog.service'
  _cmd 'sudo systemctl disable rsyslog.service'
  _cmd 'sudo systemctl mask rsyslog.service'


# Disable SNAPD
_task "disable snapd"
   _cmd 'sudo systemctl stop snapd.service'
   _cmd 'sudo systemctl disable snapd.service'
   _cmd 'sudo systemctl mask snapd.service'


# grub
#_task "update grub"
#   _cmd 'sudo sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/Id" /etc/default/grub'
#   _cmd 'echo "GRUB_CMDLINE_LINUX_DEFAULT=\"ipv6.disable=1 quiet splash\"" | sudo tee -a /etc/default/grub'
#   printf "${OVERWRITE}"


# Disable compilers
_task "disable compilers"
   sudo chmod 000 /usr/bin/byacc >/dev/null 2>&1
   sudo chmod 000 /usr/bin/yacc >/dev/null 2>&1
   sudo chmod 000 /usr/bin/bcc >/dev/null 2>&1
   sudo chmod 000 /usr/bin/kgcc >/dev/null 2>&1
   sudo chmod 000 /usr/bin/cc >/dev/null 2>&1
   sudo chmod 000 /usr/bin/gcc >/dev/null 2>&1
   sudo chmod 000 /usr/bin/*c++ >/dev/null 2>&1
   sudo chmod 000 /usr/bin/*g++ >/dev/null 2>&1
   # 755 to bring them back online
   # It is better to restrict access to them
   # unless you are working with a specific one


# Kernel Tuning
#_task "tune kernel for security"
#   _cmd 'sysctl kernel.randomize_va_space=1'
   # Enable IP spoofing protection
#   _cmd 'sysctl net.ipv4.conf.all.rp_filter=1'
   # Disable IP source routing
#   _cmd 'sysctl net.ipv4.conf.all.accept_source_route=0'
   # Ignoring broadcasts request
#   _cmd 'sysctl net.ipv4.icmp_echo_ignore_broadcasts=1'
   # Make sure spoofed packets get logged
#   _cmd 'sysctl net.ipv4.conf.all.log_martians=1'
#   _cmd 'sysctl net.ipv4.conf.default.log_martians=1'
   # Disable ICMP routing redirects
#   _cmd 'sysctl -w net.ipv4.conf.all.accept_redirects=0'
#   _cmd 'sysctl -w net.ipv6.conf.all.accept_redirects=0'
#   _cmd 'sysctl -w net.ipv4.conf.all.send_redirects=0'
   # Disables the magic-sysrq key
#   _cmd 'sysctl kernel.sysrq=0'
   # Turn off the tcp_timestamps
#   _cmd 'sysctl net.ipv4.tcp_timestamps=0'
   # Enable TCP SYN Cookie Protection
#   _cmd 'sysctl net.ipv4.tcp_syncookies=1'
   # Enable bad error message Protection
#   _cmd 'sysctl net.ipv4.icmp_ignore_bogus_error_responses=1'
   # RELOAD WITH NEW SETTINGS
#   _cmd 'sysctl -p'


# remove unrequired services & packages
_task "remove unrequired services & packages"
   _cmd 'sudo apt-get purge --auto-remove xinetd nis yp-tools tftpd atftpd tftpd-hpa -y'
   _cmd 'sudo apt-get purge --auto-remove telnetd rsh-server rsh-redone-server whoopsie -y'
   _cmd 'sudo apt-get purge --auto-remove nfs-kernel-server nfs-common portmap rpcbind autofs'
#   _cmd 'sudo apt-get purge --auto-remove git curl wget -y'
   _cmd 'sudo apt-get autoremove -y'
   _cmd 'sudo apt-get autoclean -y'
#   _cmd 'sudo update-rc.d avahi-daemon disable'


# Clean disk space
_task "clean up disk space"
   _cmd 'sudo find /var/log -type f -delete'
   _cmd 'sudo rm -rf /usr/share/man/*'
   _cmd 'sudo apt-get autoremove -y'
   _cmd 'sudo apt-get autoclean -y'


# reset system
_task "reload system"
   _cmd 'sudo sysctl -p'
   _cmd 'sudo update-grub2'
   _cmd 'sudo systemctl restart systemd-timesyncd'
   _cmd 'sudo ufw --force enable'
   _cmd 'sudo service ssh restart'


# finish last task
printf "${OVERWRITE}${LGREEN} [✓]  ${LGREEN}${TASK}\n\n\n"

# remove conduro.log
sudo rm conduro.log >/dev/null 2>&1

# Scan system for Virus & rootkits
if [[ $__VIRUS == "Y" ]]; then
    printf "=============== Virus Scan =====================\n"
	clamscan --infected --remove --recursive /
    printf "\n\n=============== Rootkit Scan =====================\n"
	chkrootkit
fi

# reboot
duration=$SECONDS
printf "Script Execution: $(($duration / 60)) minutes and $(($duration % 60)) seconds.\n\n"

_AskYN "Reboot? (y/n)" "Y" && __prompt=$REPLY
if [[ $__prompt == "Y" ]]; then
    sudo reboot
fi

# exit
exit 0

# # description
# _task "disable multipathd"
#     _cmd 'systemctl stop multipathd'
#     _cmd 'systemctl disable multipathd'
#     _cmd 'systemctl mask multipathd'

# # description
# _task "disable cron"
#     _cmd 'systemctl stop cron'
#     _cmd 'systemctl disable cron'
#     _cmd 'systemctl mask cron'

# # description
# _task "disable fwupd"
#     _cmd 'systemctl stop fwupd.service'
#     _cmd 'systemctl disable fwupd.service'
#     _cmd 'systemctl mask fwupd.service'


# # description
# _task "disable qemu-guest"
#     _cmd 'apt-get remove qemu-guest-agent -y'
#     _cmd 'apt-get remove --auto-remove qemu-guest-agent -y' 
#     _cmd 'apt-get purge qemu-guest-agent -y' 
#     _cmd 'apt-get purge --auto-remove qemu-guest-agent -y'

# # description
# _task "disable policykit"
#     _cmd 'apt-get remove policykit-1 -y'
#     _cmd 'apt-get autoremove policykit-1 -y' 
#     _cmd 'apt-get purge policykit-1 -y' 
#     _cmd 'apt-get autoremove --purge policykit-1 -y'

# # description
# _task "disable accountsservice"
#     _cmd 'service accounts-daemon stop'
#     _cmd 'apt remove accountsservice -y'

