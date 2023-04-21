#!/bin/bash

# Install OpenVPN
yum update -y
yum install epel-release -y
yum install openvpn easy-rsa -y

# Copy the server configuration file and edit it
cp /usr/share/doc/openvpn*/sample/sample-config-files/server.conf /etc/openvpn/
sed -i 's/;tls-auth/tls-auth/g' /etc/openvpn/server.conf
sed -i 's/;cipher AES-128-CBC/cipher AES-256-CBC/g' /etc/openvpn/server.conf
sed -i 's/;user nobody/user nobody/g' /etc/openvpn/server.conf
sed -i 's/;group nobody/group nobody/g' /etc/openvpn/server.conf
sed -i 's/dh dh2048.pem/dh dh4096.pem/g' /etc/openvpn/server.conf

# Generate the server key and certificate
cp -r /usr/share/easy-rsa/ /etc/openvpn/
cd /etc/openvpn/easy-rsa/
./easyrsa init-pki
./easyrsa build-ca
./easyrsa build-server-full server nopass

# Generate the Diffie-Hellman parameters
./easyrsa gen-dh

# Copy the keys and certificates to the server
cd /etc/openvpn/easy-rsa/pki
cp ca.crt ca.key dh.pem /etc/openvpn
cp issued/server.crt /etc/openvpn/server.crt
cp private/server.key /etc/openvpn/server.key

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/99-sysctl.conf
sysctl -p /etc/sysctl.d/99-sysctl.conf

# Configure the firewall rules
firewall-cmd --set-default-zone=drop

# Allow incoming traffic to the OpenVPN server port (default is UDP port 1194)
firewall-cmd --zone=public --add-port=1194/udp --permanent

# Allow outgoing traffic from the OpenVPN server
firewall-cmd --zone=public --add-forward-chain=ACCEPT --permanent
firewall-cmd --zone=trusted --add-forward-chain=ACCEPT --permanent

# Allow traffic from the OpenVPN clients to the local network
firewall-cmd --zone=trusted --add-source=10.8.0.0/24 --permanent

# Allow traffic from the OpenVPN clients to the OpenVPN server
firewall-cmd --zone=public --add-source=10.8.0.0/24 --permanent
firewall-cmd --zone=trusted --add-source=10.8.0.0/24 --permanent

# Block all other incoming traffic
firewall-cmd --zone=public --remove-service=ssh --permanent
firewall-cmd --zone=public --remove-service=dhcpv6-client --permanent
firewall-cmd --zone=public --remove-service=http --permanent
firewall-cmd --zone=public --remove-service=https --permanent
firewall-cmd --zone=public --remove-service=smtp --permanent
firewall-cmd --zone=public --remove-service=imap --permanent
firewall-cmd --zone=public --remove-service=pop3 --permanent
firewall-cmd --zone=public --remove-service=ntp --permanent
firewall-cmd --zone=public --remove-service=dns --permanent

# Reload the firewall to apply the changes
firewall-cmd --reload
