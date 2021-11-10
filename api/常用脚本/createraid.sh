#!/bin/bash 
#mdadm -Cv /dev/md0 -a yes -n 4 -l 0 /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1

#sleep 10

#mdadm -D --scan >/etc/mdadm.conf

ls -l /dev/disk/by-uuid/|awk '/md0/{print "echo \"/dev/disk/by-uuid/"$9" /opt/raid0 xfs defaults 0 0\" >>/etc/fstab"}'|bash

#mount -a
