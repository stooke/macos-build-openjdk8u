#!/bin/bash

set -e

jdk=jdk11u-dev

REPO_DIR=`pwd`/$jdk
SCRIPT_DIR=`pwd`/xx
WEBREV_BASE=`pwd`/webrevs
. $SCRIPT_DIR/tools.sh `pwd`/tools webrev mercurial
mkdir -p "$WEBREV_BASE"
repos="jdk hotspot corba nashorn langtools jaxp jaxws"
repos=""

# NOTE: the sed RE is very different on a mac vs Linux!

mkwebrev() {
	# $1 repo-dir $2 webrev-dir $3 CR#
  RD=$1
  WD=$2
  CR=`echo $3 | sed -E 's/[^0-9]*([0-9]+)[^0-9]*.*/\1/g'`
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
	mkwebrev "$REPO_DIR" $WEBREV_DIR/$2 $1
	for a in $repos ; do 
	  echo processing "$REPO_DIR/$a"
	  mkwebrev "$REPO_DIR/$a" $WEBREV_DIR/$a.$2 $1
	done
}

revert() {
set -x
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

mkrevs 8223309-jdk11u 00

