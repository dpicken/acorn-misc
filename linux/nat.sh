#!/bin/bash

# Routes eth0 and a PPP client to wlan0.
# (to e.g. provide LAN/internet access to an ethernet attached Risc PC and a serial attached A3010)
#
# Serial cable: https://www.amazon.com/dp/B075YHFMC7
#
# Example usage...
#
#   sudo ./nat.sh 192.168.2.1/24 /dev/ttyUSB0 19200 192.168.2.3
#
# ...to configure a 192.168.2.* network:
#
#      eth0: 192.168.2.1
#   Risc PC: 192.168.2.2 (Manually configure IP address and netmask, and, add 'IF "<Inet$Error>" == "" THEN Route -e add -net 0.0.0.0 192.168.2.1' to the "Routes file")
#     A3010: 192.168.2.3 (Use !InetSetup to enable Serial PPP, then, issue '*PPPConnect defaultroute')

set -euo pipefail

if [ $# -ne 4 ] || ([ $# -eq 1 ] && [ "$1" = "--help" ]); then
  echo "Usage: $(basename $0) eth0-cidr ppp-serial-device ppp-serial-baud ppp-client-ip-addr"
  exit
fi

eth0_cidr="$1"
ppp_serial_device="$2"
ppp_serial_baud="$3"
ppp_client_ip_addr="$4"

wlan0_ip_addr="$(ip -f inet address show wlan0 | grep -o 'inet.*' | cut -d ' ' -f 2 | cut -d '/' -f 1)"

ip addr add "$eth0_cidr" dev eth0 || true
pppd "$ppp_serial_device" "$ppp_serial_baud" "$wlan0_ip_addr":"$ppp_client_ip_addr" noauth lock local crtscts persist maxfail 0 holdoff 1 proxyarp

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE

# wlan0 <-> eth0
iptables -A FORWARD -i eth0 -j ACCEPT

# wlan0 <-> ppp0
iptables -A FORWARD -i ppp0 -j ACCEPT
