#!/bin/sh

set -e

echo "===== MYVPN INSTALL ====="

BASE="https://raw.githubusercontent.com/serg-data/myvpn/main"

echo "Installing dependencies..."
opkg update
opkg install jq curl wget

echo "Downloading sing-box..."

ARCH=$(uname -m)

case "$ARCH" in
x86_64) SB_ARCH="amd64" ;;
aarch64) SB_ARCH="arm64" ;;
armv7l) SB_ARCH="armv7" ;;
mips) SB_ARCH="mips" ;;
mipsel) SB_ARCH="mipsel" ;;
*)
echo "Unsupported architecture: $ARCH"
exit 1
;;
esac

wget -O /usr/bin/sing-box \
https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-linux-$SB_ARCH

chmod +x /usr/bin/sing-box

echo "Installing MYVPN scripts..."

wget -O /usr/bin/myvpn $BASE/myvpn
wget -O /usr/bin/myvpn-build $BASE/myvpn-build
wget -O /usr/bin/myvpn-apply $BASE/myvpn-apply
wget -O /usr/bin/myvpn-update $BASE/myvpn-update
wget -O /usr/bin/myvpn-watchdog $BASE/myvpn-watchdog
wget -O /usr/bin/myvpn-failover $BASE/myvpn-failover

chmod +x /usr/bin/myvpn*

echo "Creating config..."

mkdir -p /etc/myvpn

wget -O /etc/myvpn/rules.conf $BASE/rules.conf
wget -O /etc/myvpn/urltest.conf $BASE/urltest.conf
wget -O /etc/myvpn/failover.conf $BASE/failover.conf

echo primary > /etc/myvpn/current_state
echo shunt > /etc/myvpn/mode
echo auto > /etc/myvpn/run_mode

echo cloudflare > /etc/myvpn/dns_provider
echo doh > /etc/myvpn/dns_protocol
echo prefer_ipv4 > /etc/myvpn/dns_strategy

echo "Setting cron..."

CRON=/etc/crontabs/root

grep -q myvpn-watchdog $CRON || \
echo "* * * * * /usr/bin/myvpn-watchdog" >> $CRON

grep -q myvpn-failover $CRON || \
echo "*/2 * * * * /usr/bin/myvpn-failover" >> $CRON

/etc/init.d/cron restart

echo ""
echo "===== INSTALL COMPLETE ====="
echo ""
echo "Run:"
echo "myvpn"
