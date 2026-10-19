#!/bin/sh
# 99-pd-default.sh -- repair IPv6 egress for LAN clients.
#
# THE BUG
# odhcp6c installs only SOURCE-LOCKED IPv6 default routes, one per modem:
#
#     default from <modem /64>:: via <gw> dev usb0 metric 512
#
# A `from <prefix>` clause matches only packets whose source address is inside
# that modem's delegated /64. LAN clients hold ULA addresses (fd..::/8) and
# match no such clause, so they have no usable default route and their IPv6
# traffic dies silently. The uplink itself looks perfectly healthy -- the
# router's own traffic is source-correct -- which is exactly the signature of
# this bug: WAN v6 fine, LAN v6 dead.
#
# THE FIX
# When a v6 uplink comes up, install a PLAIN (non-source-locked) default via
# the same gateway, so ULA clients can egress through NAT66 (masq6 1 on the
# wan zone). The router's own /64-sourced traffic still prefers odhcp6c's
# route, because ours carries the default metric while odhcp6c's carries 512.
# Nothing about that split is guesswork: it is the verified behaviour of the
# same script on the working 25.12.5 build, which has a working uplink and
# working LAN clients with exactly this pair of routes present.
#
# WHY THIS IS NOT A VERBATIM COPY OF THE GOLD
# The gold (z8102-custom-config 89-pd-default-fix) hardcodes:
#
#     wan6 -> eth1    wan1_6 -> usb0    wan2_6 -> usb1
#
# That is correct only for a fixed two-modem Z8102 layout. ROOter's
# firstboot() pins maxmodem=4 whenever /etc/config/mwan3 exists, so wan3_6 and
# wan4_6 exist too, and a three-entry case block would silently skip them --
# the same class of hardcoding that roo_fix's own fix_wan_zone() comment
# explicitly rejects.
#
# Instead of enumerating names, this derives the device from the interface that
# actually carries an IPv6 default route. That self-scales: it covers eth1
# (wan6), every modem's wanN_6, and any uplink added later, without any list to
# keep in sync. It also needs no mwan3, so IPv6 egress does not silently depend
# on the mwan3 package being installed and configured.
#
# `ip -6 route replace` (not `add`) is used so a re-fire on a prefix rotation
# rewrites the route instead of accumulating duplicates or failing EEXIST.
#
# KNOWN LIMITATION (deliberate, not an oversight)
# If an uplink goes away, netifd removes its own routes but this plain default
# was installed via `ip` directly and is not tracked by netifd, so it can
# outlive its gateway. With multiple upstreams Linux still has the others, and
# a later ifup/connected on a surviving uplink rewrites its own route, so the
# failure mode is degraded rather than total. The obvious fix -- deleting the
# route on ifdown -- is NOT implemented here on purpose: identifying "ours"
# rather than one of odhcp6c's source-locked routes via `ip route del` is
# ambiguous and untested on real hardware. Shipping an untested deletion is
# worse than the stale route. Revisit only with a box to test it on.
#
# (Came from the z8102-custom-config gold feed, where it ships as
# 89-pd-default-fix and creates this file. Ported to the ROOter tree as a
# packaged hotplug rather than a uci-defaults, because ROOter builds its
# interfaces at boot: the route has to be installed per-ifup, not once.)

case "$ACTION" in
	ifup | connected | ifupdate) ;;
	*) exit 0 ;;
esac

# Resolve the underlying device. network.$IF.device may itself be a logical
# name ('@wanN'), which needs one more dereference. This is the same
# dereference 50-z8102-wan6-mwan3 already does in this tree.
dev=$(uci -q get network."$INTERFACE".device 2>/dev/null)
case "$dev" in
	@*) dev=$(uci -q get network."${dev#@}".device 2>/dev/null) ;;
esac
[ -n "$dev" ] || dev="$INTERFACE"

# No IPv6 default on this device means it is not a v6 uplink (yet), or has
# withdrawn. Either way there is nothing to mirror.
GW=$(ip -6 route show default dev "$dev" 2>/dev/null \
	| sed -n 's/.* via \([^ ]*\).*/\1/p' | head -n1)
[ -n "$GW" ] || exit 0

if ip -6 route replace default via "$GW" dev "$dev" 2>/dev/null; then
	logger -t pd-default "$INTERFACE ($dev): plain v6 default via $GW for LAN clients"
else
	ip -6 route add default via "$GW" dev "$dev" 2>/dev/null \
		&& logger -t pd-default "$INTERFACE ($dev): plain v6 default via $GW (add)" \
		|| logger -t pd-default "$INTERFACE ($dev): could not install default via $GW"
fi

exit 0