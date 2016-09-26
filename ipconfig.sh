#Config Network Script for Debian8 and Ubuntu 16.04 only!
#/bin/bash

interface=$(ip addr|grep "state UP"| awk '{gsub(":","");print $2}')
printf "Your network interface : \n  $interface \n\n"

printf "Enter the interface you want to setup [eth0]: "
read nic

printf "Enter IP Address you want use on $nic [192.168.1.x]: "
read setip

printf "Enter Netmask you want use on $nic [255.255.255.0]: "
read setmask

printf "Enter Gateway you want use on $nic [192.168.1.y]: "
read setgateway

printf "Enter DNS-Server you want use on $nic [168.95.1.1]: "
read setdns

printf "\n\n Setting your $nic with \n\n IP:$setip \n Netmask:$setmask \n Gateway:$setgateway \n DNS:$setdns \n\n Will overwrite your /etc/network/interfaces config file\n\n"

read -p "Are you sure ??  (Y/N): " yn

if [ "${yn}" == "Y" ] || [ "${yn}" == "y" ]; then
        echo "Overwirte Ip setting! "
        echo "auto lo
iface lo inet loopback

allow-hotplug $nic
iface $nic inet static

address $setip
netmask $setmask
gateway $setgateway
dns-nameservers $setdns" > /etc/network/interfaces

/etc/init.d/networking restart

IP=$(hostname -I|awk '{print $1}')
echo -e "Now your IP is $IP \nWebsite http://$IP\n\n"


else [ "${yn}" == "N" ] || [ "${yn}" == "n" ];
        echo "Cancel ip set up!" && exit 0
fi





