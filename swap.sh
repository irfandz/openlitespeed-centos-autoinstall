#!/usr/bin/env bash
## Intro
echo "Welcome to mySwap setup script. This script was tested on centos7 and ubuntu created by Ulwan Irfandi"
echo "Need root access to run this script"
echo "You can contact this script creator via Whatsapp +62813-3434-1313"
echo " "
echo "This script works well for Fresh Install Server, tested in Digital ocean."
echo " "
echo "Rule Swap Recommendation for normal server (Web / Mail etc):"
echo "Swap space == Equal RAM size (if RAM < 2GB)" 
echo "Swap space == 2GB size (if RAM > 2GB)" 
echo " "
echo "Rule Swap Recommendation from Oracle GURU for heavy duty oracle server with fast storage such as RAID 10:"
echo "Swap space == Equal RAM size (if RAM < 8GB)"
echo "Swap space == 0.50 times the size of RAM (if RAM > 8GB)"
echo " "
echo "CentOS Linux 7.x and RHEL 7 recommends the following rules:"
echo "Swap space == 2x the amaount of RAM (if RAM <2GB)"
echo "Swap space == Equal RAM size (if RAM > 2GB - 8GB"
echo "Swap space == at least 4GB (if RAM > 8GB)"
echo "You can read more reference at https://www.cyberciti.biz/tips/linux-swap-space.html"
echo " "

## Prompt to enter size of SWAP that want to setup 
read -p "Please enter swap size that you want (ex: 5120): " swapsize
echo "Your swap size is $swapsize"
## Create a swap file
sudo dd if=/dev/zero of=/swapfile count=$swapsize bs=1MiB
## Enable a swap file for root only
chmod 600 /swapfile
##  tell our system to set up the swap space
mkswap /swapfile
## activate swap 
swapon /swapfile
## Make the Swap File Permanent, automatically enable when system restart
echo "/swapfile   swap    swap    sw  0   0" >> /etc/fstab
## The swappiness parameter determines how often your system swaps data out of memory to the swap space. 
# This is a value between 0 and 100 that represents the percentage of memory usage that will trigger the use of swap.
# CentOS 7 defaults to a swappiness setting of 30, which is a fair middle ground for most desktops and local servers. 
# For a VPS system, we'd probably want to move it closer to 0.
sysctl vm.swappiness=50
## To make the setting persist between reboots, we can add the outputted line to our sysctl configuration file:
echo "vm.swappiness = 50" >> /etc/sysctl.conf
## This setting affects the storage of special filesystem metadata entries. 
# Constantly reading and refreshing this information is generally very costly, so storing it on the cache for longer is excellent for your system's performance.
## 100 make our system removes inode information from the cache far too quickly
sysctl vm.vfs_cache_pressure=50
## make the setting persist between reboots
echo "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf
echo
echo "Setup swap was done..."
echo "Here the details!"
free -m
