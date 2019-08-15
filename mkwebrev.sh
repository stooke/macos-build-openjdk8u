#!/bin/bash
#set -x
set -e

SCRIPT_DIR=`pwd`/xx
WEBREV_BASE=`pwd`/webrevs
. $SCRIPT_DIR/tools.sh `pwd`/tools webrev mercurial
mkdir -p "$WEBREV_BASE"
cd jdk11u*
repos="jdk hotspot corba nashorn langtools jaxp jaxws"
repos=""

mkwebrev() {
	# $1 path to repo $2 webrev dir $3 CR#
  RD=$1
  WD=$2
  CR=`echo $3 | sed s/[^0-9]*//g`
  pushd "$RD" >/dev/null
  N=`hg status | wc -l`
  if [ $N != 0 ] ; then
    webrev.ksh -b -w -o "$WD" -c $CR
    mv $WD/webrev/* $WD/webrev/..
    rmdir $WD/webrev
  else
    echo "  (no differences)"
  fi
  popd >/dev/null
}

mkrevs() {
	# $1 CR $2 NUM
	find "$REPO_DIR" -name \*.rej  -exec rm {} \; 2>/dev/null || true
	find "$REPO_DIR" -name \*.orig -exec rm {} \; 2>/dev/null || true
	WEBREV_DIR=$WEBREV_BASE/jdk-$1
	mkwebrev . $WEBREV_DIR/webrev.$2 $1
	for a in $repos ; do 
	  echo processing `pwd`/$a
	  mkwebrev $a $WEBREV_DIR/webrev.$a.$2 $1
	done
}

revert() {
	pushd "$REPO_DIR" >/dev/null
	hg revert .
	for a in $repos ; do 
	  cd $a
	  hg revert .
	  cd ..
	done
	find "$REPO_DIR" -name \*.rej  -exec rm {} \; 2>/dev/null || true 
	find "$REPO_DIR" -name \*.orig -exec rm {} \; 2>/dev/null || true
	popd >/dev/null
}

#revert

mkrevs 8214777-jdk11u 00

exit 0

## to update s01
echo "don't forget to run"
echo ##echo "  scp -vr webrevs/webrevs s01.yyz.redhat.com:~stooke/public_html"
echo "  rsync -v -r --delete webrevs stooke@cr.openjdk.java.net:."

echo ## for jtreg testing
echo export PRODUCT_HOME=`pwd`/build/linux-x86_64-server-release/images/jdk
echo export JTREG_HOME=$TOOL_DIR/jtreg/build/image/jtreg
echo export PATH=$JTREG_HOME/bin:$PATH

echo ./configure --with-jtreg=$JTHOME
echo make test TEST="test/hotspot/jtreg/gc/TestAllocateHeapAtMultiple.java"
echo make test TEST="jtreg:test/hotspot:hotspot_gc"

