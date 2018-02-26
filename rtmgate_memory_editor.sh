#!/bin/bash
# Script to modify rtmgate maximum memory (heap) value
# Chris Vidler - Dynatrace DC RUM SME 2018
#

# Location of the rtmgate config file
CONFFILE=/etc/sysconfig/rtmgate

if [ ! -w $CONFFILE ]; then
	echo -e "\e[31mERROR:\e[39m Can't update $CONFFILE, run as root/sudo"
	exit 1
fi
CONFDIR=${CONFFILE%/*}
#echo $CONFDIR
if [ ! -w $CONFDIR ]; then
	echo -e "\e[31mERROR:\e[39m Can't update $CONFDIR, run as root/sudo"
	exit 1
fi

# Grab existing memory setting
TEXT=$(grep -Po '^JAVA_OPTS="(?: *-[A-Za-z0-9:+\-=\.\/<>]+)* *-Xmx([0-9]+[MmGg])(?: -[A-Za-z0-9:+\-=\.\/<>]+)*"$' $CONFFILE)
#echo $TEXT
OLDMEM=${TEXT#*-Xmx}
OLDMEM=${OLDMEM%% *}
OLDMEM=${OLDMEM,,}

echo -e "\e[34mINFO:\e[39m Current heap maximum memory: $OLDMEM"

echo -en "Provide new heap memeory size:"
read -ei " $OLDMEM" NEWMEM

if [[ $NEWMEM =~ ([0-9]+[mMgG]) ]]; then
	NEWMEM=${BASH_REMATCH[1]}
else
	echo -e "\e[31mERROR:\e[39m Invalid response. Aborting"
	exit 1
fi
NEWMEM=${NEWMEM,,}
#echo $NEWMEM

#do some sanity checking on the new value vs. old value.
if [ ${NEWMEM: -1} == g ]; then
	((NEWVAL = ${NEWMEM::-1} * 1024))
else
	NEWVAL=${NEWMEM::-1}
fi
#echo $NEWVAL

if [ ${OLDMEM: -1} == g ]; then
	((OLDVAL = ${OLDMEM::-1} * 1024))
else
	OLDVAL=${OLDMEM::-1}
fi
#echo $OLDVAL

if [[ $NEWVAL -eq $OLDVAL ]]; then
	echo -e "\e[34mINFO:\e[39m No change requested, Exiting."
	exit 0
fi

if [[ $NEWVAL -lt $OLDVAL ]]; then
	echo -e "\e[33mWARNING:\e[39m New value (${NEWMEM}) is LESS than current value (${OLDMEM}). Continuing."
fi

if [[ $NEWVAL -gt 10240 ]]; then
	echo -e "\e[33mWARNING:\e[39m New value (${NEWMEM})is HUGE > 10G. Continuing."
fi


# Use sed to replace the memory value
echo -e "Updating old memory value (${OLDMEM}) to ${NEWVAL}m."
sed -i "s/-Xmx${OLDMEM}/-Xmx${NEWVAL}m/" "$CONFFILE"
if [ $? -ne 0 ]; then
	echo -e "\e[31mERROR:\e[39m  Failed to update $CONFFILE. Aborting."
	exit 1
fi

echo -en "\e[32mPASS:\e[39m Done, restart rtmgate to take effect ("
echo -e "sudo systemctl restart rtmgate)"
exit 0

