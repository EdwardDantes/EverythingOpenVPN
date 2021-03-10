!#bin/bash
echo "Beginning VPN Setup on this device."

apt-get install openvpn
apt-get install openssl
pwd 

cd ~/etc/opt/
wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
tar -xzvf EasyRSA-3.0.8-rc2.tgz
ls -al
echo "Remember to set line 45 of vars to uncommented EASYRSA PWD."
echo "Remember to se Country/City/Org/Email details as well."

./easyrsa init-pki
echo "Creates pki directory."

./easyrsa build-ca
#verify with openssl crl -noout -text -in /usr/local/etc/easy-rsa/pki/crl.pemCertificate Revocation List (CRL):

./easyrsa build-server-full movpn-server

./easyrsa build-client-full client1

echo "If next section fails make sure server files are named correctly."
mkdir -p /etc/opt/openvpn/movpn
chmod 700 /etc/opt/openvpn/movpn
cd /etc/opt/openvpn/movpn
PKI=<PKI_DIR>/ssladmin/active
cp -a $PKI/ca.crt movpn-ca.crt
cp -a $PKI/OpenVPN_Date_Server.crt server.crt
cp -a $PKI/OpneVPN_Date_Server.key server.key

openssl dhparam -out dh2048

echo "If next section fails make sure client files are named correctly."
cp -a $PKI/Mastering_OpenVPN_Server.crt client1.crt
cp -a $PKI/Mastering_OpneVPN_Server.key client1.key

echo "Make sure client and server .conf files are located properly and add all key certificate and key files to them."
echo "Launch the OpenVPN server first with the following command: "
echo "openvpn --config movpn-date-server.conf"


cd 


#openvpn --genkey --secret secret.key
#default value is 2048 bit key sha1 algorithm.


#Script to download and make open vpn files.
#Some code inspired by Mastering OpenVPN by Eric F Crist; Jan Just Keijser.