#!/bin/bash
# Created by Yevgeniy Goncharov, https://sys-adm.in
# Script for install MTProxy for CentOS

# Sys env / paths / etc
# -------------------------------------------------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Install Software
# -------------------------------------------------------------------------------------------\

function installSoftware() {
  yum install epel-release openssl-devel zlib-devel vim-common git -y
  yum groupinstall "Development Tools" -y
}

# Vars
SECRET_KEY=$(head -c 16 /dev/urandom | xxd -ps)
START_SCRIPT="/opt/mtproxy/start.sh"
SYSTEM_SERVICE="/etc/systemd/system/mtproxy.service"

function installMT() {
  # Install MT
  cd $SCRIPT_PATH
  git clone https://github.com/TelegramMessenger/MTProxy.git

  cd MTProxy/ && make
  mkdir /opt/mtproxy && cp objs/bin/mtproto-proxy /opt/mtproxy/

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

/opt/mtproxy/mtproto-proxy --ipv6 -u nobody -p 8888 -H 443 -S ${SECRET_KEY}  --aes-pwd /tmp/proxy-secret /tmp/proxy-multi.conf -M 14
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

