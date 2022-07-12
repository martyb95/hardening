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

USR='docker'
USR-PWD='Docker!2022'
CAREGO='192.168.10.75'
NET='CG_Cloud'


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
_AskYN "Continue (y/n)" "Y"
if [[ ${REPLY^^} != "Y" ]] ; then exit 0 ; fi

printf "\n"
_Ask "Change ssh port" "22" && __Port=$REPLY
_AskYN "Install Docker (y/n)" "Y" && __Dock=$REPLY
if [[ $__Dock == "Y" ]]; then
    _AskYN "Install NGINX Proxy Manager (y/n)" "Y" && __NGINX=$REPLY
    _AskYN "Install Docker User (y/n)" "Y" && __DockUsr=$REPLY
    _AskYN "Install Portainer (y/n)" "Y" && __Portainer=$REPLY
    _AskYN "Install Dozzle (y/n)" "Y" && __Dozzle=$REPLY
    _AskYN "Install Watchtower (y/n)" "Y" && __Watchtower=$REPLY
fi

printf "\n\n"


# script must be one of the OS's above
#if [[ $OS == "UNKNOWN" ]]; then printf "\n${LRED} Unknown operating system ($OSName). Script cannot run.${RESTORE}\n\n" ; exit 1 ; fi

# update OS dependencies
_task "update operating system"
    _cmd 'sudo apt-get  update'
    _cmd 'sudo apt-get full-upgrade -y'


# update application dependencies
_task "update app dependencies"
    _cmd 'sudo apt-get install nano curl wget ufw sed -y'
   _cmd 'sudo apt-get full-upgrade -y'


# remove existing applications
service docker status >/dev/null 2>&1
ISACT=$?
_task "remove apps to be reinstalled"
     _cmd 'sudo apt-get purge --auto-remove lynis fail2ban -y'
	 if [ "${ISACT}" = 0 ]; then _cmd 'sudo systemctl stop docker'; fi
     if [[ $(which docker) && $(sudo docker --version) ]]; then
        _cmd 'sudo apt-get remove docker docker-engine docker.io containerd runc -y'
        _cmd 'sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-compose -y'
	    _cmd 'sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg'
        _cmd 'sudo rm -rf /var/lib/docker'
        _cmd 'sudo rm -rf /var/lib/containerd'
       _cmd 'sudo rm -f /usr/local/bin/docker-compose'
     fi
     _cmd 'sudo apt update'
     _cmd 'sudo apt-get autoremove -y'
     _cmd 'sudo apt-get autoclean -y'
printf "${OVERWRITE}"


# update shell command prompt
PRPT="\[\033[0;31m\]\342\224\214\342\224\200\[\[\033[0;39m\]\u\[\033[01;33m\]@\[\033[01;96m\]\h\[\033[0;31m\]]\342\224\200[\[\033[0;32m\]\w\[\033[0;31m\]]\n\[\033[0;31m\]\342\224\224\342\224\200\342\224\200\342\224\200 \[\033[0m\]\[\e[01;33m\]\\$\[\e[0m\]"
_task "update shell command prompt"
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


# Download and Update sysctl.conf
_task "download and update sysctl.conf"
    _cmd 'sudo wget --timeout=5 --tries=2 --quiet -c https://raw.githubusercontent.com/conduro/ubuntu/main/sysctl.conf -O /etc/sysctl.conf'


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


# firewall
FILE="ip4.txt"
CF="https://www.cloudflare.com/ips-v4"
IP4=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
_task "configure firewall"
    _cmd 'sudo ufw disable'
    _cmd 'echo "y" | sudo ufw reset'
    _cmd 'sudo ufw logging off'
    _cmd 'sudo ufw default deny incoming'
    _cmd 'sudo ufw default allow outgoing'
    _cmd 'sudo ufw allow from ${CAREGO} to any port 3389 proto tcp comment "rdp"'
    _cmd 'sudo ufw allow from ${CAREGO} to any port ${__Port} proto tcp comment "ssh"'
    _cmd 'sudo ufw limit ${__Port}'
    _cmd 'sudo sed -i "/ipv6=/Id" /etc/default/ufw'
    _cmd 'echo "IPV6=no" | sudo tee -a /etc/default/ufw'
    if [ -f "$FILE" ]; then rm $FILE; fi
    wget -q -O $FILE $CF >/dev/null 2>&1 
#    while read ip4; do _cmd 'sudo ufw allow from ${ip4} to any port 80 comment "cloudflare IPs"'; done < $FILE
    while read ip4; do _cmd 'sudo ufw allow from ${ip4} to any port 443 comment "cloudflare IPs"'; done < $FILE


# grub
_task "update grub"
    _cmd 'sudo sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/Id" /etc/default/grub'
    _cmd 'echo "GRUB_CMDLINE_LINUX_DEFAULT=\"ipv6.disable=1 quiet splash\"" | sudo tee -a /etc/default/grub'
printf "${OVERWRITE}"


# Update SSHD_CONFIG 
GIT="https://raw.githubusercontent.com/martyb95/hardening/main"
_task "update sshd_conf"
      _cmd 'sudo wget --timeout=5 --tries=2 --quiet -O /etc/ssh/sshd_config $GIT/sshd.conf'
	  
_task "update ssh port"
      _cmd 'echo "Port ${__Port}" | sudo tee -a /etc/ssh/sshd_config'
	
	
# Add SSH keys to user	
_task "add SSH keys to users"
    _cmd 'mkdir -p /home/${USR}/.ssh'
    _cmd 'sudo wget --timeout=5 --tries=2 --quiet -O /home/${USR}/.ssh/authorized_keys $GIT/authorized_keys'
    if [[ -d "/home/martin" ]]; then
       _cmd 'mkdir -p /home/martin/.ssh'
       _cmd 'sudo wget --timeout=5 --tries=2 --quiet -O /home/martin/.ssh/authorized_keys $GIT/authorized_keys'
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


# Install Fail2Ban
_task "install Fail2Ban"
	_cmd 'sudo apt-get install fail2ban -y'
    _cmd 'sudo wget --timeout=5 --tries=2 --quiet -O /etc/fail2ban/jail.local $GIT/jail.local'


# Install Docker
if [[ $__Dock == "Y" ]]; then
    _task "install docker"
		 _cmd 'sudo apt install apt-transport-https ca-certificates curl software-properties-common -y'
		 _cmd 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -'
		 _cmd 'sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"'
         _cmd 'sudo apt-get update'
         sudo apt-get install docker-ce -y >/dev/null 2>&1


# Install Docker-Compose
   GIT="https://github.com/docker/compose/releases/download/v2.6.1/docker-compose-linux-x86_64"
    _task "install docker-compose"
         _cmd 'sudo curl -SL ${GIT} -o /usr/local/bin/docker-compose'
         _cmd 'chmod +x /usr/local/bin/docker-compose'


# Wait for Docker Service to Start
   _task "wait for docker service to start"
        ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
        if [[ "$ISACt" != "active" ]]; then
           X=0
           while [[ "$ISACT" != "active" ]] && [[ $X -le 10 ]]; do
               sudo systemctl start docker >> ~/docker-script-install.log 2>&1
               sleep 10s &
               pid=$! # Process Id of the previous running command
               spin='-\|/'
               i=0
               while kill -0 $pid 2>/dev/null
               do
                   i=$(( (i+1) %4 ))
                   printf "\r${spin:$i:1}"
                   sleep .1
               done
               ISACT=`sudo systemctl is-active docker`
               let X=X+1
           done
		   if [ X -gt 0 ]]; then printf "\b"; fi
       fi
printf "${OVERWRITE}"


# Create private docker network
    _task "create private docker network"
          _cmd 'sudo docker network inspect ${NET} >/dev/null 2>&1 || sudo docker network create --driver bridge ${NET}'
          if [[ -d "/home/martin" ]]; then _cmd 'sudo adduser martin docker'; fi		  
fi


# Create Docker User
if [[ $__DockUsr == "Y" ]]; then
  _task "creating docker user"
       getent passwd $USR > /dev/null 2&>1
       if [ $? -ne 0 ]; then _cmd 'sudo useradd -m -g docker -d /home/${USR}/ ${USR}'; fi    
	   _cmd 'echo ${USR}:${USR-PWD} | sudo chpasswd'
       _cmd 'echo "PS1=\"${PRPT}\"" | sudo tee -a /home/${USR}/.bashrc'
fi


# Install NGINX Proxy Manager
GIT="https://raw.githubusercontent.com/martyb95/hardening/main"
if [[ $__NGINX == "Y" ]]; then
  _task "install NGINX Proxy Manager"
	_cmd 'sudo mkdir -p /home/${USR}/nginxpm'
	_cmd 'sudo mkdir -p /home/${USR}/nginxpm/letsencrypt'
	_cmd 'sudo mkdir -p /home/${USR}/mysql'
	_cmd 'sudo wget -q -O /home/${USR}/nginxpm/docker-compose.yml $GIT/nginx-pm.yml'
	_cmd 'sudo docker-compose -f /home/${USR}/nginxpm/docker-compose.yml up -d'
fi


# Install Portainer
if [[ $__Portainer == "Y" ]]; then
  _task "install Portainer-CE"
	_cmd 'sudo mkdir -p /home/${USR}/portainer'
	_cmd 'sudo mkdir -p /home/${USR}/portainer/ssl'
	_cmd 'sudo openssl req -newkey rsa:4096 -nodes -sha256 -keyout /home/${USR}/portainer/ssl/portainer.key -x509 -days 365 -out /home/${USR}/portainer/ssl/portainer.crt -subj "/C=CA/ST=Ontario/L=Burlington/O=CareGo Tek/OU=/CN=caregotek.com"'
	_cmd 'sudo wget -q -O /home/${USR}/portainer/docker-compose.yml $GIT/portainer.yml'
	_cmd 'sudo docker-compose -f /home/${USR}/portainer/docker-compose.yml up -d'
fi


# Install Watchtower
if [[ $__Dozzle == "Y" ]]; then
  _task "install Dozzle"
	_cmd 'sudo mkdir -p /home/${USR}/dozzle'
	_cmd 'sudo wget -q -O /home/${USR}/dozzle/docker-compose.yml $GIT/dozzle.yml'
	_cmd 'sudo docker-compose -f /home/${USR}/dozzle/docker-compose.yml up -d'
fi


# Install Watchtower
if [[ $__Watchtower == "Y" ]]; then
  _task "install Watchtower"
	_cmd 'sudo mkdir -p /home/${USR}/watchtower'
	_cmd 'sudo wget -q -O /home/${USR}/watchtower/docker-compose.yml $GIT/watchtower.yml'
	_cmd 'sudo docker-compose -f /home/${USR}/watchtower/docker-compose.yml up -d'
fi


# remove unrequired services & packages
_task "remove unrequired services & packages"
    _cmd 'sudo apt-get purge --auto-remove xinetd nis yp-tools tftpd atftpd tftpd-hpa -y'
	_cmd 'sudo apt-get purge --auto-remove telnetd rsh-server rsh-redone-server -y'
	_cmd 'sudo apt-get purge --auto-remove git curl wget -y'
	

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

# reboot
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

