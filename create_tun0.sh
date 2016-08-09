#!/bin/sh

createTun()
    echo " - Create interface"
    x=`uci set network.tun0=interface  `
    x=`uci set network.tun0.proto=none `
    x=`uci set network.tun0.ifname=tun0`

createFwZone()
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


commitChanges()
    echo " - Save changes"
    x=`uci commit`

createTun
createFwZone
commitChanges
