#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export XDIR=$SCRIPT_DIR

. ./xcommon.sh

#[ -z "$*" ] && die "No options found!"

TARGET_BRANCH=
while getopts "v:" opt; do
	case $opt in
		v ) TARGET_BRANCH=$OPTARG;;
	esac
done 

[ -z "$TARGET_BRANCH" ] && TARGET_BRANCH=$XDEFBRANCH

XTOPDIR=$XDIR/$TARGET_BRANCH

if [ -d "$XDIR/$TARGET_BRANCH" ]; then
	#find . -maxdepth 1 -type f -name "*.sh" -exec cp -f {} $XTOPDIR \; >/dev/null
	rm -f $XTOPDIR/*.sh
	ln -s $XDIR/xupdate.sh $XDIR/$TARGET_BRANCH/xupdate.sh
	ln -s $XDIR/xmake.sh $XDIR/$TARGET_BRANCH/xmake.sh
	ln -s $XDIR/xcommon.sh $XDIR/$TARGET_BRANCH/xcommon.sh
	find . -maxdepth 1 -type f -name "*.config" -exec cp -f {} $XTOPDIR \; >/dev/null
	find . -maxdepth 1 -type f -name "*.json" -exec cp -f {} $XTOPDIR \; >/dev/null
	die "Directory '$TARGET_BRANCH' already exist and update the <config> <json> <script> files!"
fi

XREPOWRT=$XREPOADDR/openwrt.git
git clone $XREPOWRT -b $TARGET_BRANCH $TARGET_BRANCH
if [ "$?" != "0" ]; then
	rm -rf ./$TARGET_BRANCH
	die "Repository '$XREPOWRT' not found!"
fi



#find . -maxdepth 1 -type f -name "*.sh" -exec chmod 775 -- {} + >/dev/null
find . -maxdepth 1 -type f -name "*.sh" -exec cp {} $XTOPDIR \; >/dev/null
find . -maxdepth 1 -type f -name "*.config" -exec cp {} $XTOPDIR \; >/dev/null
find . -maxdepth 1 -type f -name "*.json" -exec cp {} $XTOPDIR \; >/dev/null

echo "Repository '$TARGET_BRANCH' created!"
#cd $XTOPDIR 

