#!/bin/bash

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
PATCH_DIR=`pwd`
popd
TOOL_DIR=$BUILD_DIR/tools
. $PATCH_DIR/tools.sh "$TOOL_DIR" autoconf mx bootstrap_jdk11 mercurial

download_graal() {
	clone_or_update https://github.com/oracle/graal.git "$BUILD_DIR/graal"
	clone_or_update https://github.com/graalvm/graalvm-demos "$BUILD_DIR/graalvm-demos"
}

build_graal() {
	cd $BUILD_DIR/graal/compiler
	mx build
	mx vm -XX:+PrintFlagsFinal -version
#	cd $BUILD_DIR/graal/vm
#	mx build
}

download_graal

export PATH=$JAVA_HOME/bin:$PATH

set -x
build_graal

