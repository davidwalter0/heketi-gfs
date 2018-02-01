#!/bin/bash

###
# Description: Script to move the glusterfs initial setup to bind mounted directories of Atomic Host.
# Copyright (c) 2016 Red Hat, Inc. <http://www.redhat.com>
#
# This file is part of GlusterFS.
#
# This file is licensed to you under your choice of the GNU Lesser
# General Public License, version 3 or any later version (LGPLv3 or
# later), or the GNU General Public License, version 2 (GPLv2), in all
# cases as published by the Free Software Foundation.
###

main () {
### Disable rpcbind.socket

  GLUSTERFS_CONF_DIR="/etc/glusterfs"
  GLUSTERFS_LOG_DIR="/var/log/glusterfs"
  GLUSTERFS_META_DIR="/var/lib/glusterd"
  GLUSTERFS_LOG_CONT_DIR="/var/log/glusterfs/container"
  GLUSTERFS_CUSTOM_FSTAB="/var/lib/heketi/fstab"

  mkdir $GLUSTERFS_LOG_CONT_DIR
  for i in $GLUSTERFS_CONF_DIR $GLUSTERFS_LOG_DIR $GLUSTERFS_META_DIR
  do
    if test "$(ls $i)"
    then
          echo "$i is not empty"
    else
          bkp=$i"_bkp"
          cp -r $bkp/* $i
          if [ $? -eq 1 ]
          then
                echo "Failed to copy $i"
                exit 1
          fi
          ls -R $i > ${GLUSTERFS_LOG_CONT_DIR}/${i}_ls
    fi
  done

  if test "$(ls $GLUSTERFS_LOG_CONT_DIR)"
  then
            echo "" > $GLUSTERFS_LOG_CONT_DIR/brickattr
            echo "" > $GLUSTERFS_LOG_CONT_DIR/failed_bricks
            echo "" > $GLUSTERFS_LOG_CONT_DIR/lvscan
            echo "" > $GLUSTERFS_LOG_CONT_DIR/mountfstab
  else
        mkdir $GLUSTERFS_LOG_CONT_DIR
        echo "" > $GLUSTERFS_LOG_CONT_DIR/brickattr
        echo "" > $GLUSTERFS_LOG_CONT_DIR/failed_bricks
  fi
  if test "$(ls $GLUSTERFS_CUSTOM_FSTAB)"
  then
        sleep 5
        pvscan > $GLUSTERFS_LOG_CONT_DIR/pvscan
        vgscan > $GLUSTERFS_LOG_CONT_DIR/vgscan
        lvscan > $GLUSTERFS_LOG_CONT_DIR/lvscan
        mount -a --fstab $GLUSTERFS_CUSTOM_FSTAB > $GLUSTERFS_LOG_CONT_DIR/mountfstab
        if [ $? -eq 1 ]
        then
              echo "mount binary not failed" >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
              exit 1
        fi
        echo "Mount command Successful" >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
        sleep 40
        cut -f 2 -d " " $GLUSTERFS_CUSTOM_FSTAB | while read -r line
        do
              if grep -qs "$line" /proc/mounts; then
                   echo "$line mounted." >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
                   if test "ls $line/brick"
                   then
                         echo "$line/brick is present" >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
                         getfattr -d -m . -e hex "$line"/brick >> $GLUSTERFS_LOG_CONT_DIR/brickattr
                   else
                         echo "$line/brick is not present" >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
                         sleep 1
                   fi
              else
		   grep "$line" $GLUSTERFS_CUSTOM_FSTAB >> $GLUSTERFS_LOG_CONT_DIR/failed_bricks
                   echo "$line not mounted." >> $GLUSTERFS_LOG_CONT_DIR/mountfstab
                   sleep 0.5
             fi
        done
        if [ "$(wc -l $GLUSTERFS_LOG_CONT_DIR/failed_bricks )" -gt 1 ]
        then
              vgscan --mknodes > $GLUSTERFS_LOG_CONT_DIR/vgscan_mknodes
              sleep 10
              mount -a --fstab $GLUSTERFS_LOG_CONT_DIR/failed_bricks
        fi
  else
        echo "heketi-fstab not found"
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

  rm  -f /etc/ssh/ssh_host_rsa_key  
  rm  -f /etc/ssh/ssh_host_dsa_key  
  rm  -f /etc/ssh/ssh_host_ecdsa_key

  ssh-keygen -f /etc/ssh/ssh_host_rsa_key   -N '' -t rsa
  ssh-keygen -f /etc/ssh/ssh_host_dsa_key   -N '' -t dsa
  # Since January 2011, OpenSSH also support ECDSA key, you may generate a new one using:
  ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521

  mkdir -p /var/lib/heketi/.ssh /etc/heketi/
  rsync -rL /var/lib/heketi/config/ssh/ /var/lib/heketi/.ssh/
  rsync -rL /var/lib/heketi/config/etc/ /etc/heketi/
  rsync -rL /var/lib/heketi/config/ssh/ /root/.ssh/
  chmod 0755 /var/lib/heketi /etc/heketi
  chmod 0700 /var/lib/heketi/.ssh /etc/heketi
  chmod 0400 /var/lib/heketi/.ssh/* /etc/heketi/*
  chmod 0444 /var/lib/heketi/.ssh/{authorized_keys,heketi_key.pub} /etc/heketi/{authorized_keys,heketi_key.pub}
  chown heketi:heketi -R /var/lib/heketi/.ssh /etc/heketi
  chown root:root -R /root/.ssh/
  sudo -u heketi bash -c 'pushd /var/lib/heketi/.ssh/; ln -s heketi_key.pub id_rsa.pub; ln -s heketi_key id_rsa'

  iptables -N HEKETI
  iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 24007 -j ACCEPT
  iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 24008 -j ACCEPT
  iptables -A HEKETI -p tcp -m state --state NEW -m tcp --dport 2222 -j ACCEPT
  iptables -A HEKETI -p tcp -m state --state NEW -m multiport --dports 49152:49251 -j ACCEPT
  iptables-save
  authconfig --updateall

  rm -f {/var,}/run/nologin
  echo "${0##*/} Script Ran Successfully"
  exit 0
}
main
