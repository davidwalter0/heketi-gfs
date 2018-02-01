#!/bin/bash -x
if [[ -d /var/lib/heketi/config ]]; then
    rsync -rla /var/lib/heketi/config/ /etc/heketi/
fi
if [[ -d /var/lib/heketi/systemd ]]; then
    rsync -rla /var/lib/heketi/systemd/ /etc/systemd/system/
fi

# if ! grep -q "heketi:x:996:996:heketi user:/var/lib/heketi:/sbin/nologin" /etc/passwd; then
#     echo "heketi:x:996:996:heketi user:/var/lib/heketi:/sbin/nologin" >> /etc/passwd
# fi
if ! grep -q "heketi:x:996:996:heketi user:/var/lib/heketi:/bin/bash" /etc/passwd; then
    echo "heketi:x:996:996:heketi user:/var/lib/heketi:/bin/bash" >> /etc/passwd
fi

if ! grep -q "heketi:x:996:" /etc/group; then
    echo "heketi:x:996:" >> /etc/group
fi
# mkdir -p /var/lib/heketi/{.ssh,config} /etc/heketi/{.ssh,config}
# chown heketi:heketi -R /var/lib/heketi /etc/heketi
# chmod 0755 /var/lib/heketi /etc/heketi
# chmod 0700 /var/lib/heketi/.ssh /etc/heketi/.ssh

mkdir -p /var/lib/heketi/.ssh /etc/heketi/
rsync -rL /var/lib/heketi/config/ssh/ /var/lib/heketi/.ssh/
rsync -rL /var/lib/heketi/config/etc/ /etc/heketi/
rsync -rL /var/lib/heketi/config/ssh/ /root/.ssh/
chmod 0755 /var/lib/heketi /etc/heketi
chmod 0700 /var/lib/heketi/.ssh /etc/heketi
chmod 0400 /var/lib/heketi/.ssh/* /etc/heketi/*
chmod 0444 /var/lib/heketi/.ssh/{authorized_keys,heketi_key.pub} /etc/heketi/{authorized_keys,heketi_key.pub}
sudo -u heketi bash -c 'pushd /var/lib/heketi/.ssh/; ln -s heketi_key.pub id_rsa.pub; ln -s heketi_key id_rsa'
chown heketi:heketi -R /var/lib/heketi /etc/heketi
chown root:root -R /root/.ssh/

authconfig --updateall
rm -f {/var,}/run/nologin
echo "${0##*/} Script Ran Successfully"

