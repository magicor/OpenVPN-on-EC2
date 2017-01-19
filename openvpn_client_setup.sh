#!/bin/bash

PublicIP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
CLIENT_CONFIG_DIR=~/client-configs
KEY_DIR=~/openvpn-ca/keys
OUTPUT_DIR=~/client-configs/files
BASE_CONFIG=~/client-configs/base.conf
CA_DIR=~/openvpn-ca

name=${1}

aws s3 cp s3://jiedong/Private/OpenVPN_config/base.conf ${BASE_CONFIG}

cd ${CA_DIR}
source vars
./build-key ${name}

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${name}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${name}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${name}.ovpn

echo 'remote '${PublicIP}' 1194' >> ${OUTPUT_DIR}/${name}.ovpn

aws s3 cp  ${OUTPUT_DIR}/${name}.ovpn s3://jiedong/Private/OpenVPN_config/Client_config/${name}.ovpn
rm ${BASE_CONFIG}
