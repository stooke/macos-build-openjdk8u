#!/bin/bash

set -x

# define JDK and repo
JDKBASE=jdk8u-dev
DEBUG_LEVEL=release
#DEBUG_LEVEL=slowdebug
## release, fastdebug, slowdebug

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
PATCH_DIR=`pwd`
popd
JDK_DIR=$BUILD_DIR/$JDKBASE

downloadjdksrc() {
	cd $BUILD_DIR
	hg revert .
	hg clone http://hg.openjdk.java.net/jdk8u/$JDKBASE $JDK_DIR
	cd $JDK_DIR
	chmod 755 get_source.sh configure
	./get_source.sh
}

patchjdk() {
	cd $JDK_DIR
	hg revert .
	hg import --no-commit $PATCH_DIR/mac-jdk8u.patch
	for a in hotspot jdk ; do 
		cd $JDK_DIR/$a
		hg revert .
		for b in $PATCH_DIR/mac-jdk8u-$a*.patch ; do 
			hg import --no-commit $b
		done
	done
}

configurejdk() {
	pushd $JDK_DIR
	chmod 755 ./configure
	./configure --with-toolchain-type=clang \
            --with-xcode-path=$XCODE_APP \
            --includedir=$XCODE_DEVELOPER_PREFIX/Toolchains/XcodeDefault.xctoolchain/usr/include \
            --with-debug-level=$DEBUG_LEVEL \
            --with-boot-jdk=$TOOL_DIR/jdk8u/Contents/Home \
            --with-freetype-include=$TOOL_DIR/freetype/include \
            --with-freetype-lib=$TOOL_DIR/freetype/objs/.libs
	popd
}

buildjdk() {
	pushd $JDK_DIR
	make images COMPILER_WARNINGS_FATAL=false CONF=macosx-x86_64-normal-server-$DEBUG_LEVEL
	popd
}

. $PATCH_DIR/tools.sh $BUILD_DIR/tools freetype autoconf mercurial bootstrap_jdk8 webrev
downloadjdksrc
patchjdk
configurejdk
buildjdk

