#!/bin/bash

num=`hostname | cut -d"-" -f5`

hname="testbot$num"

echo $hname > /etc/hostname
echo $hname

sleep 3 

reboot
