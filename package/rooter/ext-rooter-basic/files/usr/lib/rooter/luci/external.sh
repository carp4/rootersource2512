#!/bin/sh

	rm -f /tmp/ipip /tmp/xpip
	curl -k --fail --connect-timeout 5 --max-time 10 'https://api.ipify.org?format=json' > /tmp/xpip 2>/dev/null || \
	curl -6 -k --fail --connect-timeout 5 --max-time 10 'https://api6.ipify.org?format=json' > /tmp/xpip 2>/dev/null || \
	curl -4 -k --fail --connect-timeout 5 --max-time 10 'https://api.ipify.org?format=json' > /tmp/xpip 2>/dev/null || \
	(curl -k --fail --connect-timeout 5 --max-time 10 'https://ifconfig.me/all.json' 2>/dev/null | sed -n 's/.*"ip_addr"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/{"ip":"\1"}/p' | head -1 > /tmp/xpip)
	if [ -s /tmp/xpip ]; then
		mv /tmp/xpip /tmp/ipip
	else
		rm -f /tmp/ipip /tmp/xpip
	fi
