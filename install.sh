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


# _header colorize the given argument with spacing
function _task {
    # if _task is called while a task was set, complete the previous
    if [[ $TASK != "" ]]; then
        printf "${OVERWRITE}${LGREEN} [✓]  ${LGREEN}${TASK}\n"
    fi
    # set new task title and print
    TASK=$1
    printf "${LBLACK} [ ]  ${TASK} \n${LRED}"
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
                                                                        
 ${YELLOW}Hardening Linux Servers    ${LPURPLE}Ver 1.35 ${RESTORE}
 
"
prompt=""
printf "${GREEN}Ok to continue (y/n) [y]: ${RESTORE}" && read prompt 
printf "${OVERWRITE}"
if [[ $prompt == "" ]] ; then prompt="y" ; fi
if [[ $prompt == "Y" ]] ; then prompt="y" ; fi
if [[ $prompt != "y" ]] ; then exit 0 ; fi


# script must be run as root
if [[ $(id -u) -ne 0 ]] ; then printf "\n${LRED} Please run as root${RESTORE}\n\n" ; exit 1 ; fi

# check for Ubuntu or Alpine
OS="UNKNOWN"
OSName=$(grep '^NAME=' /etc/os-release)
case $OSName in
  *"Ubuntu"*)
    OS="Ubuntu"
    SUDO="sudo"
    PKG="apt"
    ADD="install"
	DEL="remove"
	PURGE="--purge"	
    OPT="-y"
    UPDATE="update"
    UPGRADE="upgrade"
    UPGRADEFULL="full-upgrade"
    ;;

  *"Alpine"*)
    OS="Alpine"
    SUDO=""
    PKG="apk"
    ADD="add"
	DEL="del"
	PURGE=""
    OPT=""
    UPDATE="update"
    UPGRADE="upgrade"
    UPGRADEFULL="upgrade"
    ;;
esac

# script must be one of the OS's above
if [[ $OS == "UNKNOWN" ]]; then printf "\n${LRED} Unknown operating system ($OSName). Script cannot run.${RESTORE}\n\n" ; exit 1 ; fi

# update OS dependencies
_task "update operating system"
    _cmd '$SUDO $PKG $UPDATE'
    _cmd '$SUDO $PKG $UPGRADEFULL $OPT'


# update application dependencies
_task "update app dependencies"
    _cmd '$SUDO $PKG $ADD nano wget iptables ufw sed $OPT'
	
	
# Install Lynis
_task "install Lynis audit software"
case $OSName in
  *"Ubuntu"*)
    TMP=$(lynis show version)
	if [[ "$TMP" != "3."* ]]; then 
	_cmd 'wget -O - https://packages.cisofy.com/keys/cisofy-software-public.key | $SUDO apt-key add -'
	_cmd 'echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | $SUDO tee /etc/apt/sources.list.d/cisofy-lynis.list'
    fi
    ;;

  *"Alpine"*)
    ;;
esac
	_cmd '$PKG $UPDATE'
	_cmd '$PKG $ADD lynis'


# Install Fail2Ban
_task "install Fail2Ban"
	_cmd '$PKG $UPDATE'
	_cmd '$PKG $ADD fail2ban'
case $OSName in
  *"Ubuntu"*)
	_cmd '$SUDO systemctl status fail2ban'
    ;;

  *"Alpine"*)
    ;;
esac
	_cmd '$SUDO cp /etc/fail2ban/jail.{conf,local}'


# description
_task "update nameservers"
    _cmd '$SUDO truncate -s0 /etc/resolv.conf'
    _cmd 'echo "nameserver 1.1.1.1" | $SUDO tee -a /etc/resolv.conf'
    _cmd 'echo "nameserver 1.0.0.1" | $SUDO tee -a /etc/resolv.conf'

# description
_task "update ntp servers"
case $OS in
  "Ubuntu")
    _cmd '$SUDO truncate -s0 /etc/systemd/timesyncd.conf'
    _cmd 'echo "[Time]" | $SUDO tee -a /etc/systemd/timesyncd.conf'
    _cmd 'echo "NTP=time.cloudflare.com" | $SUDO tee -a /etc/systemd/timesyncd.conf'
    _cmd 'echo "FallbackNTP=ca.pool.ntp.org" | $SUDO tee -a /etc/systemd/timesyncd.conf'
    ;;

  "Alpine")
    ;;
esac


case $OS in
  "Ubuntu")
      # Download and Update sysctl.conf
      _task "download and update sysctl.conf"
          _cmd 'wget --timeout=5 --tries=2 --quiet -c https://raw.githubusercontent.com/conduro/ubuntu/main/sysctl.conf -O /etc/sysctl.conf'

      # Download and Update sshd_config
      _task "download and update sshd_config"
          _cmd 'wget --timeout=5 --tries=2 --quiet -c https://raw.githubusercontent.com/conduro/ubuntu/main/sshd.conf -O /etc/ssh/sshd_config'

      # disable system logging
      _task "disable system logging"
          _cmd 'systemctl stop systemd-journald.service'
          _cmd 'systemctl disable systemd-journald.service'
          _cmd 'systemctl mask systemd-journald.service'
          _cmd 'systemctl stop rsyslog.service'
          _cmd 'systemctl disable rsyslog.service'
          _cmd 'systemctl mask rsyslog.service'

      # description
      _task "disable snapd"
          _cmd 'systemctl stop snapd.service'
          _cmd 'systemctl disable snapd.service'
          _cmd 'systemctl mask snapd.service'
    ;;

  "Alpine")
     _task "Modprobe Kernel for UFW"
	     _cmd 'modprobe -v ip_tables'
         _cmd 'modprobe -v ip6_tables'
		 _cmd 'modprobe -v iptable_nat'
#         _cmd 'insmod /lib/modules/5.4.43-1-virt/kernel/net/netfilter/x_tables.ko 
#         _cmd 'insmod /lib/modules/5.4.43-1-virt/kernel/net/ipv4/netfilter/ip_tables.ko ip6_tables'
         _cmd 'rc-update add iptables'
         _cmd 'rc-update add ip6tables'
    ;;
esac

# firewall
IP4=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
CAREGO="216.113.113.154"
WINSRV="192.168.1.10"

_task "configure firewall"
    _cmd '$SUDO ufw disable'
    _cmd 'echo "y" | $SUDO ufw reset'
    _cmd '$SUDO ufw logging off'
    _cmd '$SUDO ufw default deny incoming'
    _cmd '$SUDO ufw default allow outgoing'
    _cmd '$SUDO ufw allow 443/tcp comment "https"'
	_cmd '$SUDO ufw allow from 216.113.113.154 to ${WINSRV} port 3389 proto tcp comment "rdp"'
    printf "${YELLOW} [?]  specify ssh port [leave empty for 22]: ${RESTORE}"
    read prompt && printf "${OVERWRITE}" && if [[ $prompt != "" ]]; then
		_cmd '$SUDO ufw allow from ${CAREGO} to ${IP4} port ${prompt} proto tcp comment "ssh"'
	    _cmd '$SUDO ufw limit ${prompt}'
        _cmd 'echo "Port ${prompt}" | $SUDO tee -a /etc/ssh/sshd_config'
    else 
		_cmd '$SUDO ufw allow from ${CAREGO} to ${IP4} port 22 proto tcp comment "ssh"'
	    _cmd '$SUDO ufw limit ssh'
    fi
    _cmd '$SUDO sed -i "/ipv6=/Id" /etc/default/ufw'
    _cmd 'echo "IPV6=no" | $SUDO tee -a /etc/default/ufw'


# Install Docker
prompt=""
printf "\n${YELLOW} Do you want to install Docker [Y/n]? ${RESTORE}"
read prompt && printf "${OVERWRITE}" && if [[ $prompt == "Y" ]] ; then prompt="y" ; fi
if [[ $prompt == "y" || $prompt == "Y" ]]; then
  _task "install docker"
    _cmd '$SUDO mkdir -p ~/docker/'  
    _cmd '$SUDO $PKG $ADD curl $OPT'
    _cmd '$SUDO curl -fsSL https://get.docker.com | sh'
    _cmd '$SUDO $PKG $ADD docker-compose $OPT'
	_cmd '$SUDO usermod -aG docker "${USER}"'
	
	# Create Docker User
	prompt=""
	printf "\n${YELLOW} Do you want to create a docker user [Y/n]? ${RESTORE}"
	read prompt && printf "${OVERWRITE}" && if [[ $prompt == "Y" ]] ; then prompt="y" ; fi
	if [[ $prompt == "y" || $prompt == "Y" ]]; then
	  _task "creating docker user"
		_cmd '$SUDO useradd -m -d /home/docker/ docker'
		_cmd 'echo docker:Docker$2@2@ | chpasswd'
		_cmd '$SUDO usermod -aG docker docker'
	fi

	
	# Install NGINX Proxy Manager
	prompt=""
	printf "\n${YELLOW} Do you want to install NGINX Proxy Manager [Y/n]? ${RESTORE}"
	read prompt && printf "${OVERWRITE}" && if [[ $prompt == "Y" ]] ; then prompt="y" ; fi
	if [[ $prompt == "y" || $prompt == "Y" ]]; then
	  _task "install NGINX Proxy Manager"
		_cmd '$SUDO mkdir -p /home/docker/nginxpm'
		_cmd '$SUDO mkdir -p /home/docker/mysql'
	#	 _cmd 'curl https://github.com/martyb95/Docker/blob/897155e5ca68f58e00a439bc812b0dbb70b89702/nginx-pm.yml -o /home/docker/nginxpm/docker-compose.yml'
	#    _cmd '$SUDO /home/docker/nginxpm/docker-compose up -d'	
	fi


	# Install Portainer
	prompt=""
	printf "\n${YELLOW} Do you want to install Portainer [Y/n]? ${RESTORE}"
	read prompt && printf "${OVERWRITE}" && if [[ $prompt == "Y" ]] ; then prompt="y" ; fi
	if [[ $prompt == "y" || $prompt == "Y" ]]; then
	  _task "install Portainer-CE"
		_cmd '$SUDO mkdir -p /home/docker/portainer'
		_cmd '$SUDO mkdir -p /home/docker/portainer/ssl'
		_cmd 'openssl req -newkey rsa:4096 -nodes -sha256 -keyout /home/docker/portainer/ssl/portainer.key -x509 -days 365 -out /home/docker/portainer/ssl/portainer.crt'
	#	 _cmd 'curl https://github.com/martyb95/Docker/blob/897155e5ca68f58e00a439bc812b0dbb70b89702/portainer.yml -o /home/docker/portainer/docker-compose.yml'
	#    _cmd '$SUDO /home/docker/portainer/docker-compose up -d'	
	fi
	
	# Install Watchtower
	prompt=""
	printf "\n${YELLOW} Do you want to install Watchtower [Y/n]? ${RESTORE}"
	read prompt && printf "${OVERWRITE}" && if [[ $prompt == "Y" ]] ; then prompt="y" ; fi
	if [[ $prompt == "y" || $prompt == "Y" ]]; then
	  _task "install Watchtower"
		_cmd '$SUDO mkdir -p /home/docker/watchtower'
	#	 _cmd 'curl https://github.com/martyb95/Docker/blob/897155e5ca68f58e00a439bc812b0dbb70b89702/watchtower.yml -o /home/docker/watchtower/docker-compose.yml'
	#    _cmd '$SUDO /home/docker/watchtower/docker-compose up -d'	
	fi
fi



# grub
_task "update grub"
case $OS in
  "Ubuntu")
    _cmd '$SUDO sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/Id" /etc/default/grub'
    _cmd 'echo "GRUB_CMDLINE_LINUX_DEFAULT=\"ipv6.disable=1 quiet splash\"" | $SUDO tee -a /etc/default/grub'
    ;;

  "Alpine")
    ;;
esac

# remove unrequired services & packages
_task "remove unrequired services & packages"
    _cmd '$SUDO $PKG $PURGE $DEL xinetd nis yp-tools tftpd atftpd tftpd-hpa'
	_cmd '$SUDO $PKG $PURGE $DEL telnetd rsh-server rsh-redone-server'
	_cmd '$SUDO $PKG $PURGE $DEL curl git'	
	

# Clean disk space
_task "clean up disk space"
    _cmd '$SUDO find /var/log -type f -delete'
    _cmd '$SUDO rm -rf /usr/share/man/*'
    if [[ $OS = "Ubuntu" ]]; then
       _cmd '$SUDO $PKG autoremove $OPT'
       _cmd '$SUDO $PKG autoclean $OPT'
    fi



# reset system
_task "reload system"
case $OS in
  "Ubuntu")
    _cmd '$SUDO sysctl -p'
    _cmd '$SUDO update-grub2'
    _cmd '$SUDO systemctl restart systemd-timesyncd'
    _cmd '$SUDO ufw --force enable'
    _cmd '$SUDO service ssh restart'
    ;;

  "Alpine")
    _cmd 'rc-service chronyd restart'
    _cmd 'ufw --force enable'
    _cmd 'rc-service ssh restart'
    ;;
esac

# finish last task
printf "${OVERWRITE}${LGREEN} [✓]  ${LGREEN}${TASK}\n"

# remove conduro.log
$SUDO rm conduro.log

# reboot
prompt=""
printf "\n${YELLOW} Do you want to reboot [Y/n]? ${RESTORE}"
read prompt && printf "${OVERWRITE}" && if [[ $prompt == "Y" ]] ; then prompt="y" ; fi
if [[ $prompt == "y" || $prompt == "Y" ]]; then
    $SUDO reboot
fi

# exit
exit 1

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

