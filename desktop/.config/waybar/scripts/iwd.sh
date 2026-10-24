#!/bin/sh
# Waybar iwd/wifi status for a wireless interface.

IFACE="${IWD_IFACE:-wlan0}"
FA="<span font_family='Font Awesome 7 Free'>"

case "$IFACE" in
'' | -* | *[!A-Za-z0-9_.:-]*) IFACE=wlan0 ;;
esac

json_escape() {
	printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e 's/\r/\\r/g'
}

markup_escape() {
	printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

link=$(iw dev "$IFACE" link 2>/dev/null)
iface_json=$(json_escape "$IFACE")

if [ -z "$link" ] || printf '%s' "$link" | grep -q "Not connected"; then
	printf '{"text":"%s\\uf1eb</span> off","tooltip":"%s: disconnected","class":"disconnected","alt":"disconnected"}\n' \
		"$FA" "$iface_json"
	exit 0
fi

ssid=$(printf '%s\n' "$link" | sed -n 's/^[[:space:]]*SSID: //p')
dbm=$(printf '%s\n' "$link" | sed -n 's/^[[:space:]]*signal: \(-\{0,1\}[0-9]*\) dBm.*/\1/p')

ssid=$(printf '%s' "$ssid" | LC_ALL=C tr -d '\000-\037')

case "$dbm" in
'' | *[!0-9-]*) dbm='' ;;
esac

if [ -n "$dbm" ] && [ "$dbm" -ge -50 ] 2>/dev/null; then
	quality=100
elif [ -n "$dbm" ]; then
	quality=$((2 * (dbm + 100)))
else
	quality=0
fi

[ "$quality" -lt 0 ] && quality=0
[ "$quality" -gt 100 ] && quality=100

ssid_json=$(json_escape "$ssid")
ssid_tooltip=$(json_escape "$(markup_escape "$ssid")")

printf '{"text":"%s\\uf1eb</span> %s%%","tooltip":"%s\\n%s · %s dBm","class":"connected","alt":"connected"}\n' \
	"$FA" "$quality" "$ssid_tooltip" "$iface_json" "${dbm:-?}"
