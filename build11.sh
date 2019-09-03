#!/bin/bash

# CONFIG_ARGS is used when building JavaFX into JDK11
CONFIG_ARGS=$1

set -e

# define JDK and repo
JDKBASE=jdk11u-dev
#DEBUG_LEVEL=release
#DEBUG_LEVEL=slowdebug
DEBUG_LEVEL=fastdebug
## release, fastdebug, slowdebug
JDK_CONFIG=macosx-x86_64-normal-server-$DEBUG_LEVEL

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
SCRIPT_DIR=`pwd`
popd
PATCH_DIR="$SCRIPT_DIR/jdk11u-patch"
JDK_DIR="$BUILD_DIR/$JDKBASE"
TOOL_DIR="$BUILD_DIR/tools"

downloadjdk11usrc() {
	if ! test -d "$JDK_DIR" ; then
		hg clone http://hg.openjdk.java.net/jdk-updates/$JDKBASE "$JDK_DIR"
	else
		pushd "$JDK_DIR"
		hg pull -u
		popd
	fi
}

patchjdk() {
	if test -f "$PATCH_DIR/mac-jdk11u.patch" ; then
		pushd "$JDK_DIR"
		hg import -f --no-commit "$PATCH_DIR/mac-jdk11u.patch"
		popd
	fi
}

configurejdk() {
	pushd "$JDK_DIR"
	chmod 755 ./configure
	./configure --with-toolchain-type=clang \
            --includedir=$XCODE_DEVELOPER_PREFIX/Toolchains/XcodeDefault.xctoolchain/usr/include \
            --with-debug-level=$DEBUG_LEVEL \
            --with-jtreg="$TOOL_DIR/jtreg" \
            --with-boot-jdk=$JAVA_HOME $CONFIG_ARGS
	popd
}

buildjdk() {
	pushd "$JDK_DIR"
	IMAGES=bootcycle-images legacy-images
	make $IMAGES CONF=$JDK_CONFIG
	popd
}

testjdk() {
	TESTS=$*
	JDK_HOME="$JDK_DIR/build/$JDK_CONFIG/images/jdk"
	JT_WORK="$BUILD_DIR/jtreg"
	pushd "$JDK_DIR"
	jtreg -w "$JT_WORK/work" -r "$JT_WORK/report" -jdk:$JDK_HOME $TESTS
	popd
}

testgtest() {
	TESTS=$*
	JDK_HOME="$JDK_DIR/build/$JDK_CONFIG/images/jdk"
	pushd "$JDK_DIR"
	make test-hotspot-gtest
	popd
}

. $SCRIPT_DIR/tools.sh "$TOOL_DIR" autoconf mercurial bootstrap_jdk11 jtreg
downloadjdk11usrc
patchjdk
configurejdk
buildjdk
#testgtest test/hotspot/gtest/classfile/test_symbolTable.cpp
#testjdk jdk/java/net/httpclient/ByteArrayPublishers.java

