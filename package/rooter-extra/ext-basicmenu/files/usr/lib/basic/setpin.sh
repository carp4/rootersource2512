#!/bin/sh

log() {
	modlog "SetPIN" "$@"
}

pin=$1
if [ "$pin" = "---" ]; then
	pin=""
fi
uci set profile.simpin.pin=$pin
uci commit profile
