#!/bin/bash
set -x

sudo yum install iptables-services -y
sudo systemctl enable iptables
sudo systemctl start iptables

# wait for eth1
while ! ip link show dev eth1; do
  sleep 1
done

# enable IP forwarding and NAT
sudo sysctl -q -w net.ipv4.ip_forward=1
sudo sysctl -q -w net.ipv4.conf.eth1.send_redirects=0

sudo /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo /sbin/iptables -F FORWARD
sudo service iptables save

# prevent setting the default route to eth0 after reboot
rm -f /etc/sysconfig/network-scripts/ifcfg-eth0

# switch the default route to eth1
sudo ip route del default dev eth0

# wait for network connection
curl --retry 10 https://www.ietf.org/

# reestablish connections
sudo systemctl restart amazon-ssm-agent.service
