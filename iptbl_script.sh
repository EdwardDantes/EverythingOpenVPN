#!/bin/bash
# Flush
#CHANGE VALUES BELOW THAT ARE IN SMALL BRACKETS <VALUE>
#Fully loaded VPN server firewall settings...
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
echo "What is the client IP address?"
read clientIP
echo "What is the client router IP address?"
read client_routerIP
echo "What is the client router IP address range?"
read client_routerRange
echo "What is the client side tun0 address in config?"
read client_tun
echo "What is the tun0 address range?"
read tun_Range
echo "What is the server IP address?"
read serverIP
echo "What is the server IP address range?"
read server_Range
echo "What is the server tun0 address?"
read server_tun
echo "What is the VPN port going to be?"
read port
echo "What protocol is being used?"
read protocol
echo "What is the DNS server address?"
read DNSaddress
echo "What is the ssh port being used?"
read ssh_port

# allow Localhost
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Make sure you can communicate with any DHCP server
iptables -A OUTPUT -d 255.255.255.255 -j ACCEPT
iptables -A INPUT -s 255.255.255.255 -j ACCEPT
iptables -A OUTPUT -d 255.255.255.0 -j ACCEPT
iptables -A INPUT -s 255.255.255.0 -j ACCEPT

# Make sure that you can communicate within your own network
iptables -A INPUT -s $tun_Range -d $client_routerRange -j ACCEPT
iptables -A OUTPUT -s $client_routerRange -d $tun_Range -j ACCEPT
iptables -A OUTPUT -s $clientIP -d $client_routerIP -j ACCEPT
iptables -A OUTPUT -s $clientIP -d $serverIP -j ACCEPT
iptables -A OUTPUT -s $client_tun -d $server_tun -j ACCEPT
iptables -A OUTPUT -d $client_tun -p $protocol -m $protocol --dport $port -j ACCEPT
iptables -A INPUT -d $client_tun -p $protocol -m $protocol --dport $port -j ACCEPT
iptables -A OUTPUT -d $DNSaddress -p $protocol -m $protocol --dport $port -j ACCEPT
iptables -A INPUT -d $DNSaddress -p $protocol -m $protocol --dport $port -j ACCEPT


# Allow established sessions to receive traffic:
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#Allow input from OpenVPN server
iptables -A INPUT -i eth0 -p $protocol -m $protocol -d $serverIP --dport $port
iptables -A INPUT -p $protocol -m $protocol --dport #Enter OpenVPN port number here
#iptables -A INPUT -i eth0 -j ACCEPT -d #enter

# Allow TUN
iptables -A INPUT -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -j ACCEPT
iptables -A OUTPUT -o tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t filter -A FORWARD -p $protocol -d $server_tun --dport $ssh_port -j ACCEPT
iptables -t filter -A FORWARD -p $protocol --dport $ssh_port -j ACCEPT


#allow for Outbound Network Time Protocol (NTP) requests
iptables -A OUTPUT -o eth0 -p udp -m udp --sport 123 --dport 123 -j ACCEPT

#allow outbound email
iptables -A INPUT -i eth0 -p tcp --destination-port 25 -m comment --comment "Allow Outbound Email" -m state --state NEW -j ACCEPT 

#allow outbound DNS lookups
iptables -A OUTPUT -o eth0 -p udp -m udp --dport 53 -m comment --comment "Allow outbound DNS lookups" -j ACCEPT
iptables -A OUTPUT -o eth0 -p $protocol -m $protocol --dport $port -m comment --comment "Allow outbound DNS lookups" -j ACCEPT

#allow outbound OpenVPN server access
iptables -A OUTPUT -p tcp -m $protocol -d $serverIP --dport $port -j ACCEPT

# allow VPN connection
iptables -I OUTPUT -p $protocol --destination-port $port -m comment --comment "Allow VPN connection" -j ACCEPT

# allow SSH connection
iptables -I OUTPUT -p tcp --destination-port $ssh_port -m comment --comment "Allow SSH connection" -j ACCEPT
iptables -I INPUT -p tcp --destination-port $ssh_port -m state --state NEW -j ACCEPT

# allow HTTP(S) connection
iptables -I OUTPUT 1 -p tcp --destination-port 443 -m comment --comment "Allow HTTPS connection" -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp -m tcp --dport 80 -m state --state NEW -j ACCEPT

# allow outbound DHCP request
iptables -A OUTPUT -p udp --dport 67:68 --sport 67:68 -j ACCEPT

# More rules for VPN
iptables -A FORWARD -i tun+ -j ACCEPT
iptables -t filter -A FORWARD -s $server_Range -d $client_routerRange -j ACCEPT
iptables -t filter -A FORWARD -s $client_routerRange -d $server_Range -j ACCEPT
iptables -t nat -A POSTROUTING -s $server_Range -d $client_routerRange  -o tun+ -j MASQUERADE
iptables -t nat -A POSTROUTING -s $client_routerRange -d $server_Range -o tun+ -j MASQUERADE
iptables -t nat -A POSTROUTING -s $client_routerRange -d $tun_Range -o tun+ -j MASQUERADE

#Allow your ipaddress to access server

# Block All
iptables -A OUTPUT -j DROP
iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP

#Make sure you can log back in
iptables -I OUTPUT -s $serverIP -d $clientIP -j ACCEPT
iptables -I INPUT -s $clientIP -d $serverIP -j ACCEPT
iptables -I FORWARD -d $clientIP -j ACCEPT

# Log all dropped packages, debug only.
iptables -N logging
iptables -A INPUT -j logging
iptables -A OUTPUT -j logging
iptables -A logging -m limit --limit 2/min -j LOG --log-prefix "IPTables general: " --log-level 7
iptables -A logging -j DROP

echo "saving"

iptables-save > /etc/iptables-'date+%F'.rules

echo "done"

