#!/bin/bash

if ! grep -q "heketi:x:996:996:heketi user:/var/lib/heketi:/sbin/nologin" /etc/passwd; then
    echo "heketi:x:996:996:heketi user:/var/lib/heketi:/sbin/nologin" >> /etc/passwd
fi
if ! grep -q "heketi:x:996:" /etc/group; then
    echo "heketi:x:996:" >> /etc/group
fi
chown heketi:heketi -R /var/lib/heketi /etc/heketi
chmod 700 /var/lib/heketi/.ssh

iptables -N HEKETI
iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 24007 -j ACCEPT
iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 24008 -j ACCEPT
iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 2222 -j ACCEPT
iptables -A HEKETI -p tcp -m state --state NEW -m multiport --dports 49152:49251 -j ACCEPT
iptables-save
sudo chown -R heketi:heketi /var/lib/heketi; systemctl daemon-reload; systemctl restart -l heketi; systemctl status -l heketi
