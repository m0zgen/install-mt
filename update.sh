#!/bin/bash

# Sys env / paths / etc
# -------------------------------------------------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin


rm -rf /tmp/MTProxy
cd /tmp/
git clone https://github.com/TelegramMessenger/MTProxy.git
cd /tmp/MTProxy
make
systemctl stop mtproxy.service
rm /opt/mtproxy/mtproto-proxy
cp /tmp/MTProxy/objs/bin/mtproto-proxy /opt/mtproxy
rm -rf /tmp/MTProxy
systemctl daemon-reload
systemctl start mtproxy.service