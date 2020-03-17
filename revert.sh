#!/bin/bash

set -e

jdk=jdk8u-dev

BUILD_DIR=`pwd`
REPO_DIR="$BUILD_DIR/$jdk"
pushd `dirname $0`
SCRIPT_DIR=`pwd`
popd
WEBREV_BASE="$BUILD_DIR/webrevs"
TOOL_DIR="$BUILD_DIR/tools"
. "$SCRIPT_DIR/tools.sh" "$TOOL_DIR" mercurial
mkdir -p "$WEBREV_BASE"
repos="jdk hotspot corba nashorn langtools jaxp jaxws"
#repos=""

# NOTE: the sed RE is very different on a mac vs Linux!

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
	pushd "$REPO_DIR" >/dev/null
	find "$REPO_DIR" -name \*.rej  -exec rm {} \; 2>/dev/null || true 
	find "$REPO_DIR" -name \*.orig -exec rm {} \; 2>/dev/null || true
	popd
}

revert() {
	pushd "$REPO_DIR" >/dev/null
	find "$REPO_DIR" -name \*.rej  -exec rm {} \; 2>/dev/null || true 
	find "$REPO_DIR" -name \*.orig -exec rm {} \; 2>/dev/null || true
	hg revert .
	for b in `hg status | grep ^\? | cut -c 3-` ; do
		echo removing $b
		rm "$b"
	done
	for a in $repos ; do 
	  cd $a
	  hg revert .
	  for b in `hg status | grep ^\? | cut -c 3-` ; do
		echo removing $b
		rm "$b"
	  done
	  cd ..
	done
	popd >/dev/null
}

revert
#update
#clean
