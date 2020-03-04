#!/bin/bash

### 节点服务主机初始化脚本
### init_system.sh

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Separator_1="——————————————————————————————————————————————————"

HOSTNAME=$1
ZABBIX_IP=$2

usage() {
    cat <<EOF
脚本使用说明：
usage: $(basename $0) "HOSTNAME" "ZABBIX_IP"

      HOSTNAME：系统主机名；
      ZABBIX_IP：zabbix server or proxy ip；

EOF
}

#验证系统主机名
is_hostname() {
    [ -z "${HOSTNAME}" ] && return 0
    return 1
}
is_hostname && { usage; echo -e "${Error} 请输入系统主机名参数"; exit 1; }


#验证zabbix ip
is_zbx_ip() {
    [ -z "${ZABBIX_IP}" ] && return 0
    return1
}
is_zbx_ip && { usage; echo -e "${Error} 请输入 zabbix server or proxy ip 参数"; exit 1; }

#修改系统主机名
Set_hostname() {
    hostnamectl set-hostname ${HOSTNAME}
}

Mount_disk() {
    mkdir /app
    mkfs.xfs /dev/vdb
    mount /dev/vdb /app
    mkdir -p /app/bp
    sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
    echo '/dev/vdb /app xfs defaults 0 0' >> /etc/fstab
}


Zabbix_init() {
    cd /srv/
    while true
    do
        wget --no-check-certificate https://raw.githubusercontent.com/Sy20191225/zabbix-agent/master/downlocal.sh >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            break
        else
            continue
    done
    sh /srv/downlocal.sh ${ZABBIX_IP}
}


Stop_firewalld() {
    systemctl stop firewalld
    systemctl disable firewalld
}



Salt_minion_conf() {
    yum -y install salt-minion
    echo "master: 152.136.179.205" >> /etc/salt/minion
    Hostname=`hostname`
    echo $Hostname > /etc/salt/minion_id
    systemctl restart salt-minion
    systemctl enable salt-minion
}

Set_hostname
Mount_disk
Zabbix_init
Stop_firewalld
Salt_minion_conf
