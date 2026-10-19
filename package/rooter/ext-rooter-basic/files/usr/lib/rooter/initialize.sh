#!/bin/sh
. /lib/functions.sh

ROOTER=/usr/lib/rooter
ROOTER_LINK="/tmp/links"

CODENAME="ROOter "
if [ -f "/etc/codename" ]; then
	source /etc/codename
fi

log() {
	modlog "ROOter Initialize" "$@"
}

#
# do_zone() -- rebuild the wan firewall zone's network membership.
#
# Two separate defects are fixed here.
#
# 1. Membership was written with uci_set as ONE space-joined string:
#
#       list network 'wan wan6 wan1 wan2 wan3 wan4 wan5 wwan2 wwan5'
#
#    `uci set` does not split whitespace on a list option, so fw4 looked up a
#    single network literally named "wan wan6 wan1 ...", found no such network,
#    and dropped the zone. wan1/wan1_6 were then in no zone at all and fell
#    through to `jump handle_reject`. We delete the option and add one element
#    per member instead.
#
# 2. The guard was `echo $network | grep "wan1"`, which matches its OWN output:
#    once a zone had been written it contained "wan1", so the guard could never
#    allow a repair. There was no path back to a correct zone. We compare
#    against the membership we actually want, which is re-runnable.
#
# Sizing is $MODCNT, read from maxmodem, not a hardcoded ceiling: the call site
# is after MODCNT is resolved and after the wanN/wanN_6 sections have been
# created and committed, so every name added refers to a network that exists.
#
# Non-destructive by design: members already in the zone (wwan2, wwan5) are
# preserved. Splitting $network on whitespace is what un-collapses the legacy
# single-element blob.
#
# The firewall is restarted ONLY when something actually changed. Restarting it
# unconditionally would bounce the firewall on every boot.
#
do_zone() {
	local config=$1
	local name
	local network
	local members
	local member
	local want
	local have
	local COUNTER=1
	local changed=0

	config_get name $1 name
	[ "$name" = "wan" ] || return 0

	# Nothing sensible to size to: leave the zone exactly as it is rather than
	# guess. (MODCNT comes from maxmodem.maxmodem.maxmodem.)
	case "$MODCNT" in
		''|*[!0-9]*) return 0 ;;
	esac
	[ "$MODCNT" -ge 1 ] || return 0

	config_get network $1 network

	members="$network"
	while [ $COUNTER -le "$MODCNT" ]; do
		members="$members wan$COUNTER wan${COUNTER}_6"
		let COUNTER=COUNTER+1
	done

	# de-duplicate, preserving first-seen order, so the comparison below is
	# stable across boots instead of oscillating
	want=""
	for member in $members; do
		case " $want " in
			*" $member "*) continue ;;
		esac
		want="$want $member"
	done

	have=$(echo $network | tr -s ' \t\n' ' ' | sed 's/^ *//;s/ *$//')
	want=$(echo $want | sed 's/^ *//;s/ *$//')

	if [ "$have" != "$want" ]; then
		uci -q delete firewall."$config".network
		for member in $want; do
			uci add_list firewall."$config".network="$member"
		done
		changed=1
	fi

	# masq6 is what enables NAT66 -- keep setting it, and keep counting it as
	# a change worth restarting for.
	MASQ6=$(uci_get firewall "$config" masq6)
	if [ -z "$MASQ6" ]; then
		uci_set firewall "$config" masq6 "1"
		changed=1
	fi

	[ "$changed" = 1 ] || return 0

	uci_commit firewall
	/etc/init.d/firewall restart
}

firstboot() {
	HO=$(uci get system.@system[-1].hostname)
	if [ $HO = "OpenWrt" ]; then
		uci set system.@system[-1].hostname="ROOter"
		echo "ROOter" > /proc/sys/kernel/hostname
	fi
	if [ $HO = "LEDE" ]; then
		uci set system.@system[-1].hostname="ROOter"
		echo "ROOter" > /proc/sys/kernel/hostname
	fi
	uci set system.@system[-1].cronloglevel="9"
	uci commit system

	AP=$(uci -q get profile.default.apn)
	if [ -z "$AP" ]; then
		uci set profile.default.apn="internet"
		uci commit profile
	fi

	log "ROOter First Boot finalized"

	# do_zone() used to run HERE. It cannot: at this point maxmodem has not been
	# resolved yet and the wanN / wanN_6 network sections have not been created
	# or committed, so a zone built from them referenced sections that did not
	# exist. The call has moved down to just after `uci commit mwan3`, where
	# $MODCNT is known and the interfaces exist. See the call site below.

	source /etc/openwrt_release
	DR=$DISTRIB_RELEASE
	if [ $DR = "SNAPSHOT" ]; then
		DR="21.02.2"
	fi
	tone=$(echo "$DR" | grep "2")
	mxchge=$(uci -q get maxmodem.maxmodem.custom)
	if [ "$mxchge" != "1" ]; then
		if [ -e /etc/config/mwan3 ]; then
			uci set maxmodem.maxmodem.maxmodem=4
		else
			uci set maxmodem.maxmodem.maxmodem=2
		fi
		uci commit maxmodem
	fi
}

if [ -e /tmp/installing ]; then
	exit 0
fi


log " Initializing Rooter"

sed -i -e 's|/etc/savevar|#removed line|g' /etc/rc.local

[ -f "/etc/firstboot" ] || {
	firstboot
}

#
# Set the maximum number of modems supported
#
MAX_MODEMS=$(uci -q get maxmodem.maxmodem.maxmodem)
MODCNT=$MAX_MODEMS

mkdir -p $ROOTER_LINK

uci delete modem.Version
uci set modem.Version=version
uci set modem.Version.ver=$CODENAME
uci commit modem

source /etc/openwrt_release
rm -f /etc/openwrt_release
if [ $DISTRIB_RELEASE = "SNAPSHOT" ]; then
	DISTRIB_RELEASE="Master"
fi
if [ -e /etc/custom ]; then
	lua $ROOTER/customname.lua
	DISTRIB_DESCRIPTION=$(uci get modem.Version.ver)
	DISTRIB_REVISION=" "
else
	DISTRIB_DESCRIPTION=$(uci get modem.Version.ver)" ( "$DISTRIB_ID" "$DISTRIB_RELEASE" )"
	DISTRIB_REVISION=" "
fi
echo "$(uci get modem.Version.ver)" > /etc/revision
echo 'DISTRIB_ID="'"$DISTRIB_ID"'"' >> /etc/openwrt_release
echo 'DISTRIB_RELEASE="'"$DISTRIB_RELEASE"'"' >> /etc/openwrt_release
echo 'DISTRIB_REVISION="'"$DISTRIB_REVISION"'"' >> /etc/openwrt_release
echo 'DISTRIB_CODENAME="'"$DISTRIB_CODENAME"'"' >> /etc/openwrt_release
echo 'DISTRIB_TARGET="'"$DISTRIB_TARGET"'"' >> /etc/openwrt_release
echo 'DISTRIB_DESCRIPTION="'"$DISTRIB_DESCRIPTION"'"' >> /etc/openwrt_release
echo 'OPENWRT_RELEASE="'"$DISTRIB_DESCRIPTION"'"' >> /usr/lib/os-release

#/usr/lib/rooter/luci/external.sh &

MODSTART=1
WWAN=0
USBN=0
ETHN=1
BASEPORT=0
WDMN=0
if
	ifconfig eth1 &>/dev/null
then
	if [ -e "/sys/class/net/eth1/device/bInterfaceProtocol" ]; then
		ETHN=1
	else
		ETHN=2
	fi
fi

echo 'MODSTART="'"$MODSTART"'"' > /tmp/variable.file
echo 'WWAN="'"$WWAN"'"' >> /tmp/variable.file
echo 'USBN="'"$USBN"'"' >> /tmp/variable.file
echo 'ETHN="'"$ETHN"'"' >> /tmp/variable.file
echo 'WDMN="'"$WDMN"'"' >> /tmp/variable.file
echo 'BASEPORT="'"$BASEPORT"'"' >> /tmp/variable.file

echo 'MODCNTX="'"$MODCNT"'"' > /tmp/modcnt
uci set modem.general.max=$MODCNT
uci set modem.general.modemnum=1
uci set modem.general.smsnum=1
uci set modem.general.miscnum=1

OPING=$(uci -q get modem.ping.alive)
if [ ! -z $OPING ]; then
	uci delete modem.ping
fi

ifname1="ifname"
if [ -n "$tone" -o -e /etc/newstyle ]; then
	ifname1="device"
fi

COUNTER=1
while [ $COUNTER -le 5 ]; do
	uci -q delete network.wan$COUNTER
	uci -q delete network.wan$COUNTER"_6"
	uci delete modem.modem$COUNTER
	uci delete modem.modeminfo$COUNTER
	let COUNTER=COUNTER+1
done
uci commit network
uci commit modem

COUNTER=1
while [ $COUNTER -le $MODCNT ]; do
	uci delete modem.modem$COUNTER
	uci set modem.modem$COUNTER=modem
	uci set modem.modem$COUNTER.empty=1

	IPEX=$(uci get modem.pinginfo$COUNTER.alive)
	if [ -z $IPEX ]; then
		uci set modem.pinginfo$COUNTER=pinfo$COUNTER
		uci set modem.pinginfo$COUNTER.alive="0"
	fi

	INEX=$(uci get modem.modeminfo$COUNTER)
	if [ -z $INEX ]; then
		uci set modem.modeminfo$COUNTER=minfo$COUNTER
	fi

	rm -f $ROOTER_LINK/getsignal$COUNTER
	rm -f $ROOTER_LINK/reconnect$COUNTER
	rm -f $ROOTER_LINK/create_proto$COUNTER
	$ROOTER/signal/status.sh $COUNTER "No Modem Present"

	uci -q delete network.wan$COUNTER
	uci set network.wan$COUNTER=interface
	uci set network.wan$COUNTER.proto=dhcp
	uci set network.wan$COUNTER.metric=$COUNTER"0"
	uci set network.wan$COUNTER.${ifname1}="wan"$COUNTER
	
	uci -q delete network.wan$COUNTER"_6"
	uci set network.wan$COUNTER'_6'=interface
	uci set network.wan$COUNTER'_6'.proto=none
	uci set network.wan$COUNTER'_6'.${ifname1}="@wan$COUNTER"
	uci set network.wan$COUNTER'_6'.metric=$COUNTER"0"

	if [ -e /etc/config/mwan3 ]; then
		ENB=$(uci -q get mwan3.wan$COUNTER.enabled)
		if [ ! -z $ENB ]; then
			uci set mwan3.wan$COUNTER.enabled=1
			uci set mwan3.wan$COUNTER'_6'.enabled=1
		fi
	fi

	if [ -e /etc/config/failover ]; then
		uci delete failover.Modem$COUNTER
		uci set failover.Modem$COUNTER=member
	fi

	let COUNTER=COUNTER+1
done

if [ -e /etc/config/failover ]; then
	uci delete failover.Wan
	EXX=$(uci get network.wan)
	if [ ! -z $EXX ]; then
		uci set failover.Wan=member
	fi
	uci delete failover.Hotspot
	uci set failover.Hotspot=member
	uci commit failover
	ENB=$(uci get failover.enabled.enabled)
	if [ $ENB = "1" ]; then
		if [ -e $ROOTER/connect/failover.sh ]; then
			log "Starting Failover System"
			$ROOTER/connect/failover.sh &
		fi
	fi
fi

PRO=$(uci -q get network.wan.proto)
if [ ! -z $PRO ]; then
	uci set network.wan.metric="1"
fi

SM=$(uci get modem.sms)
if [ -z $SM ]; then
	uci set modem.sms="sms"
	uci set modem.sms.menable="0"
	uci set modem.sms.slots="0"
fi

uci commit modem
uci commit network
if [ -e /etc/config/mwan3 ]; then
	uci commit mwan3
fi

# Rebuild the wan firewall zone here, and only here.
#
# This is the earliest point at which every precondition holds:
#   - $MODCNT is resolved (read from maxmodem.maxmodem.maxmodem above)
#   - wanN / wanN_6 network sections have been created (the loop above)
#   - network has been committed          (so fw4 sees the interfaces)
#   - mwan3 has been committed
# Inside firstboot() none of these were true, which is why this call was moved.
config_load firewall
config_foreach do_zone zone

if [ -e $ROOTER/removeipv6.sh ]; then
	$ROOTER/removeipv6.sh
fi

if [ -e /etc/hotplug.d/10-motion ]; then
	rm -f /etc/hotplug.d/10-motion
fi
if [ -e /etc/hotplug.d/20-mjpg-streamer ]; then
	rm -f /etc/hotplug.d/20-mjpg-streamer
fi
if [ -e /etc/hotplug.d/50-printer ]; then
	rm -f /etc/hotplug.d/50-printer
fi
if [ -e $ROOTER/special.sh ]; then
	$ROOTER/special.sh
fi

lua $ROOTER/gpiomodel.lua

HO=$(uci get system.@system[-1].hostname)
if [ $HO = "OpenWrt" ]; then
	uci set system.@system[-1].hostname="ROOter"
	uci commit system
fi

if [ -e /usr/lib/lua/luci/model/cbi/admin_system/cronnew.lua ]; then
	mv -f /usr/lib/lua/luci/model/cbi/admin_system/cronnew.lua /usr/lib/lua/luci/model/cbi/admin_system/crontab.lua
fi


if [ -f "/etc/firstboot" ]; then
	echo 'FIRSTBOOT="'"1"'"' > /etc/firstboot
else
	echo 'FIRSTBOOT="'"0"'"' > /etc/firstboot
	echo 'BOOTTIME="'"$(date +%s)"'"' > /tmp/boottime
fi

modis=$(uci -q get basic.basic.modem)
if [ ! -z $modis ]; then
	uci set basic.basic.modem="1"
	uci commit basic
fi

#
# Added modems to various drivers
#
echo "1546 1146" > /sys/bus/usb-serial/drivers/option1/new_id
echo "106c 3718" > /sys/bus/usb-serial/drivers/option1/new_id

# end of bootup
echo "0" > /tmp/bootend.file

/etc/init.d/dnsmasq restart

chown -R root:root /etc/dropbear/
chmod 700 /etc/dropbear/
chmod 644 /etc/dropbear/authorized_keys 2>/dev/null

if [ ! -z $tone ]; then
	[ -e /etc/newstyle ] || touch /etc/newstyle
fi

