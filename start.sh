#!/bin/bash

TOKEN=""

help()
{
	echo "##############################################"
	echo "###    Pls make sure open \"OEM lock\"       ###"
	echo "###  Example:./start.sh unlock -s SN       ###"
	echo "###  unlock/lock:   unlock/lock bootloader ###"
	echo "###  -s SN:   unlock/lock one device       ###"
	echo "###  -a:      unlock/lock all devices      ###"
	echo "###                                        ###"
	echo "###             Add by lxj                 ###"
	echo "##############################################"
}

unlock()
{	

	echo "#################  Unlock bootloader #######################"
	checkDevice $1
	
	echo "3.Get device token"
	sudo ./fastboot oem get_identifier_token > token.txt 2>&1
	TOKEN=`cat token.txt | grep "^[0-9]\{1\}"`
	
	if [ "${TOKEN}" = "" ];
	then
		echo "Identifier token: Null"
		sudo ./fastboot reboot  > /dev/null 2>&1
		exit -1
	fi
	echo "Identifier token: $TOKEN"
	
	
	echo "4.Unlock bootloader"
	sudo ./signidentifier_unlockbootloader.sh ${TOKEN} rsa4096_vbmeta.pem signature.bin > /dev/null 2>&1
	
	echo "5.flashing bootloader,Please press volume down botton !!!"
	sudo ./fastboot flashing unlock_bootloader signature.bin > /dev/null 2>&1
	sleep 5
    if [ $? = 0 ] ;
    then
		echo "flashing success!"
    else
		echo "flashing fail! Is already unlock?"
	fi
	
	echo "6.Reboot"
	sudo ./fastboot reboot  > /dev/null 2>&1
}

lock()
{

	echo "#################  Lock bootloader #######################"
	checkDevice $1
	
	echo "3.Lock bootloader"
	sudo ./fastboot flashing lock_bootloader > /dev/null 2>&1
	
    if [ $? = 0 ] ;
    then
		echo "lock success!"
    else
		echo "lock fail!"
	fi
	
	echo "4.Reboot"
	sudo ./fastboot reboot > /dev/null 2>&1
}


checkDevice()
{
	echo "1.Reboot into bootloader: $1"
	if [ "$1"  !=  "" ];then
		adb -s $1 reboot bootloader
		if [ $? = 1 ];then
			echo "Make sure SN: $1 is right and usb debug is open!!"
			exit -1
		fi
	else
		adb reboot bootloader
		if [ $? = 1 ];then
			exit -1
		fi
	fi
	sleep 5
	echo "2.Check devices"
	devices=`sudo ./fastboot devices | grep "fastboot"`
	if [ "${devices}" = "" ];
	then
		echo "Not found devices"
		sudo ./fastboot reboot > /dev/null 2>&1
	fi
}


lockAll()
{
	echo "List Devices"
	devices=`adb devices | grep -sw "device"`
	devices=${devices//device/''} #remove char:device
	for line in ${devices}
	do
		lock $line
	done
}

unlockAll()
{
	echo "List Devices"
	devices=`adb devices | grep -sw "device"`
	devices=${devices//device/''} #remove char:device
	for line in ${devices}
	do
		unlock $line
	done
}



#echo "Choose 1 to unlock or  2 to lock device"
#read input
#if [ "$input" = "2" ];
#then
#	lock
#else
#	unlock
#fi


if [ $# -lt 1 ] || [ $# -ge 4 ] ;then
	echo "Must has more than one argument!"
	help
	exit -1
fi

if [ "$1" = "lock" ];then
	if [ "$2" = "-s" ];then
		lock $3
	elif [ "$2" = "-a" ];then
		lockAll
	else
		lock
	fi
elif [ "$1" = "unlock" ];then
	if [ "$2" = "-s" ];then
		unlock $3
	elif [ "$2" = "-a" ];then
		unlockAll
	else
		unlock
	fi
fi
