#!/bin/bash

/bin/echo "fs.file-max = 65536" >> /etc/sysctl.conf
/sbin/sysctl -p


echo "*          soft     nproc          65535" >> /etc/security/limits.conf
echo "*          hard     nproc          65535" >> /etc/security/limits.conf
echo "*          soft     nofile         65535" >> /etc/security/limits.conf
echo "*          hard     nofile         65535" >> /etc/security/limits.conf


/sbin/reboot
