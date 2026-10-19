#!/bin/sh
. /lib/functions.sh

log() {
	modlog "Email" "$@"
}

result=`ps | grep -i "sendcust1.sh" | grep -v "grep" | wc -l`
if [ $result -lt 1 ]; then
	if [ ! -z "$1" ]; then
		cust="$1"
	else
		cust=$(uci -q get zerotier.zerotier.cust)
	fi
	/usr/lib/zerotier/sendcust1.sh "$cust" &
fi