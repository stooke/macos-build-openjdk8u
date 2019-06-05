#!/bin/bash

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
PATCH_DIR=`pwd`
popd
TOOL_DIR=$BUILD_DIR/tools
. $PATCH_DIR/tools.sh "$TOOL_DIR" autoconf mx bootstrap_jdk8 mercurial

build_jvmci_jdk8() {
	if test -d "$TOOL_DIR/jvmci_jdk8" ; then
		return
	fi
	download_and_open https://github.com/graalvm/openjdk8-jvmci-builder/releases/download/jvmci-19-b01/openjdk-8u212-jvmci-19-b01-darwin-amd64.tar.gz "$TOOL_DIR/jvmci_jdk8"
}

build_mx() {
	clone_or_update https://github.com/graalvm/mx.git "$TOOL_DIR/mx"
}

download_graal() {
	clone_or_update https://github.com/oracle/graal.git "$BUILD_DIR/graal"
}

build_graal() {
	cd $BUILD_DIR/graal/compiler
	mx build
	mx vm
#	cd $BUILD_DIR/graal/vm
#	mx build
}

build_jvmci_jdk8
build_mx
download_graal

export JAVA_HOME=$TOOL_DIR/jvmci_jdk8/Contents/Home
export PATH=$JAVA_HOME/bin:$TOOL_DIR/mx:$PATH

set -x
build_graal

