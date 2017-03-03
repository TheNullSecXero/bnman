#!/bin/bash

################################################################################
## bnman                                                                      ##
##                                                                            ##
## AUTHOR                                                                     ##
## TheXero                                                                    ##
################################################################################

################################################################################
## change to match your systems configuration                                 ##
################################################################################
DIRECTORY="/home/thexero/wireless" ## wireless configuration directory        ##
WLAN="wlp3s0"                      ## wifi interface                          ##
LAN="enp0s25"                      ## ethernet inteface                       ##
################################################################################
## do not edit below this line                                                ##
################################################################################

################################################################################
## script version                                                             ##
################################################################################
VERSION="0.01"

banner()
{

    cat << EOF

################################################################################
##              BBBBBB  NN     NN MM       MM   AAAA   NN     NN              ##
##              BB    B NNN    NN MMM     MMM AA    AA NNN    NN              ##
##              BB    B NN N   NN MM M   M MM AA    AA NN N   NN              ##
##              BBBBBB  NN  N  NN MM  M M  MM AA    AA NN  N  NN              ##
##              BB    B NN   N NN MM   M   MM AAAAAAAA NN   N NN              ##
##              BB    B NN    NNN MM       MM AA    AA NN    NNN              ##
##              BBBBBB  NN     NN MM       MM AA    AA NN     NN              ##
################################################################################

EOF

}

main()
{
    banner
    if [ "$(id -u)" != "0" ]; then
        printf "This script must be run as root\n" 1>&2
        exit
    fi
    if [ -z $1 ]; then
        usage
        exit
    fi
    parse_args ${@}
}

usage()
{
    cat << EOF
 usage: $0 <arg>
 example: $0 -w wireless/BThub3.wpa

 OPTIONS:
     -h: print help and exit
     -s: perform a WiFi scan
     -o: connect to network using ifconfig
     -w: connect to network using wpa_supplicant
     -p: enable privacy (start openvpn)

EOF
}

parse_args()
{
    while getopts hksco:w:p flags;
    do
        case "${flags}" in
            h)
                usage;
                exit;
                ;;

            s)
                INT=$WLAN;
                wifi_scan;
                ;;

            w)
                NETWORK=$OPTARG;
                INT=$WLAN;
                refresh_wlan;
                wpa_wifi;
                ;;

            c)
                clean;
                ;;
            o)
                NETWORK=$OPTARG;
                INT=$WLAN;
                connect_open;
                ;;
            k)
                printf "Killing wlan\r\n";
                clean;
                ;;
            p)
                pia;
                ;;
            *)
                usage;
                exit;
                ;;
        esac
    done
    exit
}

connect_open()
{
    clean;
    fake_mac $INT;
    iwconfig $INT essid "$ESSID"
    sleep 2
    iwconfig $INT ap any
    sleep 2
    getip $INT
}

connect_wep()
{
    iwconfig $INT essid $ESSID key $PASSWORD
}

connect_wpa()
{
    wpa_supplicant -i$WLAN -B -c"$*"
}

getip()
{
    dhcpcd $WLAN
}

fake_mac()
{
    modprobe iwlwifi
    sleep 2
    ifconfig $INT down
    macchanger -r $INT
    ifconfig $INT up
}

restore_mac()
{
    ifconfig $INT down
    macchanger -p $INT
    ifconfig $INT up
}

wifi_scan()
{
    #WIFI=$(iwlist $WLAN scan  | egrep "ESSID|Address ")
    WIFI=$(iw dev $WLAN scan | egrep "SSID|BSS|Group cipher")
    printf "%s\r\n"  "$WIFI"

}

home_wifi()
{
    fake_mac
    connect_wpa $HOME
    sleep 15
    getip $WLAN
}

wpa_wifi()
{
    clean
    fake_mac
    connect_wpa $NETWORK
    sleep 15
    getip $WLAN
}

connect_config()
{
    echo "need to finish"
}

tor()
{
    /etc/init.d/tor start
}

pia()
{
    /etc/init.d/openvpn stop
    TOTAL_CONFIGS=$(ls /etc/openvpn/pia/*ovpn | wc -l)
    SELECT=$((1 + $RANDOM % $TOTAL_CONFIGS ))
    CHOSEN=$(ls /etc/openvpn/pia/*ovpn | nl | grep $SELECT | head -1 )
    CONFIG=$(echo $CHOSEN | cut -d ' ' -f 2)
    cp $CONFIG /etc/openvpn/openvpn.conf
    /etc/init.d/openvpn start
}

clean()
{
    rmmod cdc_ncm
    rmmod iwldvm
    rmmod iwlwifi
    rmmod e1000e
    rfkill unblock wifi
    killall dhcpcd
    killall wpa_supplicant
    killall openvpn
}

refresh_wlan()
{
    rmmod iwldvm
    rmmod iwlwifi
    modprobe iwlwifi
    sleep 1
}

kill_wlan()
{
    killall dhcpcd;
    killall wpa_supplicant;
    rmmod iwldvm;
    rmmod iwlwifi;
    rfkill block all;
    killall openvpn;
}

main ${@}
