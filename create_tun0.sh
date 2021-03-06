#!/bin/sh

createTun() {
    echo " - Create interface"
    x=`uci set network.tun0=interface`
    x=`uci set network.tun0.proto=none`
    x=`uci set network.tun0.ifname=tun0`
}

createFwZone() {
    echo " - Create fw zone"
    if [ `uci show firewall|grep tun0 -c` -eq 0 ]; then
        x=`uci add firewall zone`
        echo " - Setup fw zone"
        x=`uci set firewall.@zone[-1].name=tun0`
        x=`uci set firewall.@zone[-1].forward=REJECT`
        x=`uci set firewall.@zone[-1].output=ACCEPT`
        x=`uci set firewall.@zone[-1].input=REJECT`
        x=`uci set firewall.@zone[-1].network=tun0`
        x=`uci set firewall.@zone[-1].masq=1`
        x=`uci set firewall.@zone[-1].mtu_fix=1`
        echo " - Create forwarding rule"
        x=`uci add firewall forwarding`
        x=`uci set firewall.@forwarding[-1].dest=tun0`
        x=`uci set firewall.@forwarding[-1].src=lan`
    else
        echo "Zone already exist"
    fi
}

commitChanges() {
    echo " - Save changes"
    x=`uci commit`
}

getFiles() {
    mkdir -p /etc/openvpn
    x=`wget https://main.mob-voip.net/$username/configs/$username.conf --user=$username --password=$password --no-check-certificate -O /etc/openvpn/$username.conf`
    x=`wget https://main.mob-voip.net/$username/keys/$username.crt --user=$username --password=$password --no-check-certificate -O /etc/openvpn/$username.crt`
    x=`wget https://main.mob-voip.net/$username/keys/$username.key --user=$username --password=$password --no-check-certificate -O /etc/openvpn/$username.key`
    x=`wget https://main.mob-voip.net/$username/keys/ca.crt --user=$username --password=$password --no-check-certificate -O /etc/openvpn/ca.crt`
    x=`wget https://main.mob-voip.net/$username/keys/dh2048.pem --user=$username --password=$password --no-check-certificate -O /etc/openvpn/dh2048.pem`
    x=`wget https://main.mob-voip.net/$username/keys/ta.key --user=$username --password=$password --no-check-certificate -O /etc/openvpn/ta.key`
}

checkSoft() {
    echo "Check wget"
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
    echo "Check openvpn"
    x=`host main.mob-voip.net`
    if [ `opkg list-installed|grep openpvn -c` -eq 0 ]; then
        version=`cat /etc/openwrt_release|grep RELEASE|awk '{split(\$0,a,"="); print a[2] }'|sed s/\'\$//|sed s/^\'//|awk '{split(\$0,a,".");print a[1]}'`
        echo $version
        x=`wget --no-check-certificate https://main.mob-voip.net/_openvpn/$version/openvpn.ipk -O /tmp/openvpn.ipk`
        opkg install --force-checksum /tmp/openvpn.ipk
    fi

}

runVpn() {
    /etc/init.d/openvpn enable
    /etc/init.d/openvpn restart
}


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
    echo ""
    echo "Use $0 --username=<username> --password=<password>"
    exit 99
fi

if [ -z $password ]; then
    echo "Error. No password."
    echo ""
    echo "Use $0 --username=<username> --password=<password>"
    exit 99
fi

checkSoft
getFiles

createTun
createFwZone
commitChanges
runVpn
