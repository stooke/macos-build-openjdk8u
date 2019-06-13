#!/bin/bash
# GRAALVM_HOME=/Users/stooke/dev/ojdk/graal/vm/mxbuild/darwin-amd64/GRAALVM_SVM/graalvm-svm-20.0.0-beta.02-dev/Contents/Home

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

clean_graal() {
	cd $BUILD_DIR/graal
	for a in compiler sdk substratevm sulong tools vm truffle ; do ( cd $a ; mx clean ; cd .. ) ; done 
}

build_graal() {
	cd $BUILD_DIR/graal
	#mx --primary-suite-path compiler build
	#mx --primary-suite-path substratevm build
	#mx --primary-suite-path vm build
	mx --primary-suite-path substratevm native-image
#	mx --primary-suite-path compiler vm -XX:+PrintFlagsFinal -version 2>&1 || grep JVMCI
}

download_graal

export PATH=$JAVA_HOME/bin:$PATH

set -x
clean_graal
build_graal

