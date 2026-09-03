#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export XDIR=$SCRIPT_DIR
export XADDONSDIR=$XDIR/package/addons
FEEDSDIR=$XDIR/package/feeds
ADDONSCFG=$XDIR/../_addons.config

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color（重置颜色，必须加在文末，否则后面的输出都会变色）

. ./xcommon.sh

OPT_FULL_UPDATE=false
while getopts "f" opt; do
	case $opt in
		f) OPT_FULL_UPDATE=true;;
	esac
done

[ ! -d "$FEEDSDIR" ] && OPT_FULL_UPDATE=true

rm -rf tmp
if [ "$OPT_FULL_UPDATE" = "true" ]; then
	rm -rf feeds/luci.tmp
	rm -rf feeds/packages.tmp
	#rm -rf feeds
	#rm -rf package/feeds
	rm -rf staging_dir/packages
	rm -rf $XADDONSDIR
fi

git reset --hard HEAD

git fetch
[ "$?" != "0" ] && die "Can't fetch current repository"

git pull --force "origin" &> /dev/null 
#[ "$?" != "0" ] && die "Can't pull current repository"

CUR_BRANCH=$( git rev-parse --abbrev-ref HEAD )

git reset --hard origin/$CUR_BRANCH
[ "$?" != "0" ] && die "Can't reset current repository"

echo -e "${GREEN}SUCCESS:${NC} config feeds!"

rm -f feeds.conf
cp -f feeds.conf.default feeds.conf
feed_lst=$( get_cfg_feed_lst "$ADDONSCFG" )
for feed in $feed_lst; do
	value=$( get_cfg_feed_url "$ADDONSCFG" $feed )
	#echo "$feed = '$value'"
	echo "src-git $feed $value" >> feeds.conf
done

echo -e "${GREEN}SUCCESS:${NC} update feeds A!!"

if [ "$OPT_FULL_UPDATE" = "true" ]; then
	./scripts/feeds update -a
	./scripts/feeds install -a
	rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,v2ray-plugin,xray-plugin,geoview,shadow-tls}
	rm -rf package/addons/passwall_packages
	git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/addons/passwall_packages
	./scripts/feeds install -a
fi

echo -e "${GREEN}SUCCESS:${NC} update feeds B!!"

CLONE_ADDONS=true
if [ "$CLONE_ADDONS" = "true" ]; then
	mkdir -p "$XADDONSDIR"
	pkg_lst=$( get_cfg_expkg_lst "$ADDONSCFG" )
	for pkg in $pkg_lst; do
		value=$( get_cfg_expkg_url "$ADDONSCFG" $pkg )
		#echo "$pkg = '$value'"
		url=$( echo "$value" | cut -d " " -f 1 )
		branch=$( echo "$value" | cut -d " " -f 2 )
		#echo "'$url' / '$branch'"
		if [ ! -d "$XADDONSDIR/$pkg" ]; then
			git clone $url -b $branch $XADDONSDIR/$pkg
			[ "$?" != "0" ] && die "Can't clone repository '$url'"
		fi
	done
	if [ "$OPT_FULL_UPDATE" = "true" ]; then
		./scripts/feeds install -a
	fi
fi

echo -e "${GREEN}SUCCESS:${NC} update vermagic!!"

if [ "$OPT_FULL_UPDATE" = "true" ]; then
	if [ -f "$XDIR/vermagic_update.sh" ]; then
		./vermagic_update.sh ipq806x generic
		./vermagic_update.sh ramips mt7621
		./vermagic_update.sh mediatek mt7622
	fi
fi

if [ -f "$XDIR/luci_dispatcher.sh" ]; then
	./luci_dispatcher.sh
fi

echo -e "${GREEN}SUCCESS:${NC} All git sources updated!"
