#!/bin/bash
# Created by Yevgeniy Goncharov, https://sys-adm.in
# Script for install MTProxy for CentOS

# Sys env / paths / etc
# -------------------------------------------------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Vars
# -------------------------------------------------------------------------------------------\
RED='\033[1;31m'
GREEN='\033[1;32m'
CL='\033[0m'
#
START_SCRIPT="/opt/mtproxy/start.sh"
SYSTEM_SERVICE="/etc/systemd/system/mtproxy.service"
SERVER_IP=$(hostname -I | cut -d' ' -f1)

# Install Software
# -------------------------------------------------------------------------------------------\
function installSoftware() {
  yum install epel-release openssl-devel zlib-devel vim-common git -y
  yum groupinstall "Development Tools" -y
}

function installMT() {
  # Install MT
  cd $SCRIPT_PATH
  git clone https://github.com/TelegramMessenger/MTProxy.git

  cd MTProxy/ && make
  mkdir /opt/mtproxy && cp objs/bin/mtproto-proxy /opt/mtproxy/

  # Vars
  head -c 16 /dev/urandom | xxd -ps > $SCRIPT_PATH/secret.txt
  SECRET_KEY=$(cat $SCRIPT_PATH/secret.txt)

cat <<EOF > $START_SCRIPT
#!/bin/bash

dt=$(date '+%d%m%Y_%H%M%S');

if [ -f /tmp/proxy-secret ]; then
   mv /tmp/proxy-secret /tmp/proxy-secret-$dt
fi
curl -s https://core.telegram.org/getProxySecret -o /tmp/proxy-secret
sleep 10

if [ -f /tmp/proxy-multi.conf ]; then
    mv /tmp/proxy-multi.conf /tmp/proxy-multi-$dt.conf
fi
curl -s https://core.telegram.org/getProxyConfig -o /tmp/proxy-multi.conf

/opt/mtproxy/mtproto-proxy --ipv6 -u nobody -p 8888 -H 443 -S ${SECRET_KEY} --aes-pwd /tmp/proxy-secret /tmp/proxy-multi.conf -M 14
EOF

cat << EOF > $SYSTEM_SERVICE
[Unit]
Description=MTProxy
After=multi-user.target

[Service]
Type=simple
ExecStart=/bin/bash ${START_SCRIPT}
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

  chmod +x $START_SCRIPT
  systemctl enable mtproxy && systemctl start mtproxy && systemctl status mtproxy
}

function setupFW() {
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
}

function installUpdater() {
    cp $SCRIPT_PATH/update.sh /etc/cron.weekly/
    chmod +x /etc/cron.weekly/update.sh
}

installSoftware
installMT
installUpdater
setupFW

echo -e "Install complete! Please use this link for your MTProxy\n"
echo -e "${GREEN}tg://proxy?server=$SERVER_IP&port=443&secret=$SECRET_KEY${CL}"
echo -e "${GREEN}https://t.me/proxy?server=$SERVER_IP&port=443&secret=$SECRET_KEY${CL}"

echo  -e "\n$Links saved to {RED}$SCRIPT_PATH/t-link.txt${CL}\n"
echo "tg://proxy?server=$SERVER_IP&port=443&secret=$SECRET_KEY" > $SCRIPT_PATH/t-link.txt
echo -e "https://t.me/proxy?server=$SERVER_IP&port=443&secret=$SECRET_KEY" >> $SCRIPT_PATH/t-link.txt