#!/bin/sh

createTun() {
    echo " - Create interface"
    x=`uci set network.tun0=interface  `
    x=`uci set network.tun0.proto=none `
    x=`uci set network.tun0.ifname=tun0`
}

createFwZone() {
    echo " - Create fw zone"
    x=`uci add firewall zone                    `
    echo " - Setup fw zone"
    x=`uci set firewall.@zone[-1].name=tun0     `
    x=`uci set firewall.@zone[-1].forward=REJECT`
    x=`uci set firewall.@zone[-1].output=ACCEPT `
    x=`uci set firewall.@zone[-1].input=REJECT  `
    x=`uci set firewall.@zone[-1].network=tun0  `
    x=`uci set firewall.@zone[-1].masq=1        `
    x=`uci set firewall.@zone[-1].mtu_fix=1     `
    echo " - Create forwarding rule"
    x=`uci add firewall forwarding               `
    x=`uci set firewall.@forwarding[-1].dest=tun0`
    x=`uci set firewall.@forwarding[-1].src=lan  `
}

commitChanges() {
    echo " - Save changes"
    x=`uci commit`
}

getFiles() {
    mkdir -p /etc/openvpn
    x="wget https://main.mob-voip.net/$username/configs/$username.conf --user=$username --password=$password --no-check-certificate -O /etc/openvpn/$username.conf"
    x="wget https://main.mob-voip.net/$username/keys/$username.crt --user=$username --password=$password --no-check-certificate -O /etc/openvpn/$username.crt"
    x="wget https://main.mob-voip.net/$username/keys/$username.key --user=$username --password=$password --no-check-certificate -O /etc/openvpn/$username.key"
    x="wget https://main.mob-voip.net/$username/keys/ca.crt --user=$username --password=$password --no-check-certificate -O /etc/openvpn/ca.crt"
    x="wget https://main.mob-voip.net/$username/keys/dh2048.pem --user=$username --password=$password --no-check-certificate -O /etc/openvpn/dh2048.pem"
    x="wget https://main.mob-voip.net/$username/keys/ta.key --user=$username --password=$password --no-check-certificate -O /etc/openvpn/ta.key"

}

checkSoft() {
    if [ `opkg list-installed|grep wget -c` -eq 0 ]; then
        opkg update
        if [ $? -ne 0 ]; then
            echo "Error update opkg"
            exit 99
        fi
        opkg install wget
        if [ $? -ne 0 ]; then
            echo "Error install wget"
            exit 99
        fi
    fi
}

echo test $#
while test $# -gt 0
do
    param1=`echo $1 |awk '{split(\$0,a,"=");print a[1]}'`
    param2=`echo $1 |awk '{split(\$0,a,"=");print a[2]}'`
    case $param1 in
        --username)
            username=$param2
        ;;
        --password)
            password=$param2
        ;;
        *)
            echo >&2 "Invalid argument: $1"
        ;;
        esac
    shift
done

if [ -z $username ]; then
    echo "Error. No username."
    exit(99)
fi

if [ -z $password ]; then
    echo "Error. No password."
    exit(99)
fi

getFiles

# createTun
# createFwZone
# commitChanges