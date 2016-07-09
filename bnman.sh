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

    ## Is root?
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
     -p: enable privacy (start openvpn + privoxy)

EOF
}

parse_args()
{
    ## Function to parse command line arguments
    while getopts hksc:o:w:p flags;
    do
        case "${flags}" in

            h)
                ## invoke usage and exit
                usage;
                exit;
                ;;

            s)
                ## set the interface
                INT=$WLAN;
                ## invoke wifi scanning
                wifi_scan;
                ;;

            w)
                NETWORK=$OPTARG;
                INT=$WLAN;
                refresh_wlan;
                ## connect to other wpa wifi network
                wpa_wifi;
                ;;

            c)
                # to wite
                NETWORK=$OPTARG;
                INT=$WLAN;
                connect_config;
                ;;

            o)
                # connect to an open network
                NETWORK=$OPTARG;
                INT=$WLAN;
                connect_open;
                ;;

            k)
                # kill wifi
                printf "Killing wlan\r\n";
                kill_wlan;
                ;;

            p)
                pia;
                privoxy;
                ;;

            *)
                ## unrecognised argument
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
    
    ## connect to an openNETWORK network
    iwconfig $INT essid "$ESSID"
    sleep 2
    iwconfig $INT ap any
    sleep 2
    getip $INT

}

connect_wep()
{
    ## connect to a wep network
    iwconfig $INT essid $ESSID key $PASSWORD
}

connect_wpa()
{
    ## use wpa_supplicant tp connect to the wifi network
    wpa_supplicant -i$WLAN -B -Dnl80211 -c"$*"
}

getip()
{
    ## launcINTh dhcpcd with fake id info
    dhcpcd $WLAN

    ## launch dhclient
    #dhclient $WLAN

}

fake_mac()
{
    ## generate a fake address for the interface
    ifconfig $INT down
    macchanger -r $INT
    ifconfig $INT up
}

restore_mac()
{
    ## restore the original mac for the interface
    ifconfig $INT down
    macchanger -p $INT
    ifconfig $INT up
}

wifi_scan()
{
    ## use iwlist to scan for wifi networks
    WIFI=$(iwlist $WLAN scan  | egrep "ESSID|Address ")

    printf "$WIFI\r\n"

}

home_wifi()
{
    ## get new mac
    fake_mac

    ## connect to home home wifi
    connect_wpa $HOME
    sleep 15
    getip $WLAN
}

wpa_wifi()
{
    ## clean
    clean

    ## get a new mac
    fake_mac

    ## connect to other wifi network
    connect_wpa $NETWORK
    sleep 15
    getip $WLAN
    
}

connect_config()
{
    ## read the config file
    echo "need to finish"
}

tor()
{
    /etc/init.d/tor start
}

privoxy()
{
    /etc/init.d/privoxy start
}

pia()
{
    /etc/init.d/openvpn start
}

clean()
{
    rfkill unblock wifi&>/dev/null
    killall dhcpcd&>/dev/null
    killall wpa_supplicant&>/dev/null
}

refresh_wlan()
{
    ## removing loaded drivers
    rmmod iwldvm
    rmmod iwlwifi

    ## loading wifi drivers
    modprobe iwlwifi
    sleep 1
}

kill_wlan()
{
    ## kill all wifi
    killall dhcpcd&>/dev/null;
    killall wpa_supplicant&>/dev/null;
    rmmod iwldvm&>/dev/null;
    rmmod iwlwifi&>/dev/null;
    rfkill block all&>/dev/null;
    killall openvpn&>/dev/null;
}



################################################################################
## program starts here                                                        ##
################################################################################
main ${@}
