#!/bin/bash

set -e

jdk=jdk8u-dev

BUILD_DIR=`pwd`
REPO_DIR="$BUILD_DIR/$jdk"
SCRIPT_DIR="$BUILD_DIR/xx"
WEBREV_BASE="$BUILD_DIR/webrevs"
TOOL_DIR="$BUILD_DIR/tools"
. "$SCRIPT_DIR/tools.sh" "$TOOL_DIR" webrev mercurial
mkdir -p "$WEBREV_BASE"
repos="jdk hotspot corba nashorn langtools jaxp jaxws"
#repos=""

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
	WEBREV_DIR="$WEBREV_BASE/jdk-$1/$2"
	mkwebrev "$REPO_DIR" "$WEBREV_DIR/$2" $1
	for a in $repos ; do 
	  echo processing "$REPO_DIR/$a"
	  mkwebrev "$REPO_DIR/$a" "$WEBREV_DIR/$a.$2" $1
	done
}

update() {
	pushd "$REPO_DIR" >/dev/null
	find "$REPO_DIR" -name \*.rej  -exec rm {} \; 2>/dev/null || true 
	find "$REPO_DIR" -name \*.orig -exec rm {} \; 2>/dev/null || true
	hg pull -u
	for a in $repos ; do 
	  cd $a
	  hg pull -u
	  cd ..
	done
	popd >/dev/null
}

clean() {
	rm -fr "$REPO_DIR/build"
	find "$REPO_DIR" -name \*.rej  -exec rm {} \; 2>/dev/null || true 
	find "$REPO_DIR" -name \*.orig -exec rm {} \; 2>/dev/null || true
}

revert() {
	pushd "$REPO_DIR" >/dev/null
	find "$REPO_DIR" -name \*.rej  -exec rm {} \; 2>/dev/null || true 
	find "$REPO_DIR" -name \*.orig -exec rm {} \; 2>/dev/null || true
	hg revert .
	for a in $repos ; do 
	  cd $a
	  hg revert .
	  cd ..
	done
	popd >/dev/null
}

#revert
#update
#cd "$REPO_DIR/jdk"
#hg import -f --no-commit "$BUILD_DIR/8216965-jdk8.patch"

mkrevs jdk-8226288-jdk8u 00

