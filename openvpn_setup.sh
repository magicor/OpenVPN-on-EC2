#!/bin/bash

CA_DIR=~/openvpn-ca
UFW_RULES=/etc/ufw/before.rules

apt-get update
apt-get install openvpn easy-rsa awscli
apt-get update
apt-get upgrade

make-cadir ${CA_DIR}
#aws s3 cp s3://jiedong/Private/OpenVPN_config/vars ${CA_DIR}/vars
mv ./vars ${CA_DIR}/
mv ./server.conf /etc/openvpn/

cd ${CA_DIR}
source vars
./clean-all
./build-ca

./build-key-server server
./build-dh

openvpn --genkey --secret keys/ta.key

cd  ${CA_DIR}/keys
sudo cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn
#gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf

#aws s3 cp s3://jiedong/Private/OpenVPN_config/server.conf /etc/openvpn/server.conf
#echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p

sed -i '1 i\# END OPENVPN RULES' ${UFW_RULES}
sed -i '1 i\COMMIT' ${UFW_RULES}
sed -i '1 i\-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE' ${UFW_RULES}
sed -i '1 i\# Allow traffic from OpenVPN client to eth0' ${UFW_RULES}
sed -i '1 i\:POSTROUTING ACCEPT [0:0]' ${UFW_RULES}
sed -i '1 i\*nat' ${UFW_RULES}
sed -i '1 i\# NAT table rules' ${UFW_RULES}
sed -i '1 i\# START OPENVPN RULES' ${UFW_RULES}

sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw

ufw allow 1194/udp
ufw allow OpenSSH
ufw disable
ufw enable

systemctl start openvpn@server
systemctl status openvpn@server
ip addr show tun0

systemctl enable openvpn@server

mkdir -p ~/client-configs/files
chmod 700 ~/client-configs/files
