#!/bin/bash

DOWNLOAD_JCVMCI_JDK8=false

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
SCRIPT_DIR=`pwd`
PATCH_DIR=$SCRIPT_DIR/jdk8u-patch
popd
TOOL_DIR=$BUILD_DIR/tools
. $SCRIPT_DIR/tools.sh "$TOOL_DIR" mx 

build_graal() {
	cd $BUILD_DIR/graal
 	#mx --primary-suite-path compiler build
	#mx --primary-suite-path compiler vm -XX:+PrintFlagsFinal -version
 	#mx --primary-suite-path substratevm build
	#mx --primary-suite-path sdk build
	#mx --primary-suite-path vm build
	mx --primary-suite-path substratevm native-image foo.java
}

download_jvmci_jdk8() {
	if test -d "$TOOL_DIR/jvmci_jdk8" ; then
		return
	fi
	download_and_open https://github.com/graalvm/openjdk9-jvmci-builder/releases/download/jvmci-19-b01/openjdk-8u212-jvmci-19-b01-darwin-amd64.tar.gz "$TOOL_DIR/jvmci_jdk8"
}

build_jdk8() {
	# we're not clear on if build8.sh builds jdk8u or jdk8u-dev so try both
	# note we're also assuming a fastdebug build...
	if test -d "$BUILD_DIR/jdk8u" ; then 
		NEW_JAVA_HOME="$BUILD_DIR/jdk8u/build/macosx-x86_64-normal-server-fastdebug/images/j2sdk-image"
		return
	fi
	if test -d "$BUILD_DIR/jdk8u-dev" ; then 
		NEW_JAVA_HOME="$BUILD_DIR/jdk8u-dev/build/macosx-x86_64-normal-server-fastdebug/images/j2sdk-image"
		return
	fi
	$SCRIPT_DIR/build8.sh
	if test -d "$BUILD_DIR/jdk8u" ; then 
		NEW_JAVA_HOME="$BUILD_DIR/jdk8u/build/macosx-x86_64-normal-server-fastdebug/images/j2sdk-image"
		return
	fi
	if test -d "$BUILD_DIR/jdk8u-dev" ; then 
		NEW_JAVA_HOME="$BUILD_DIR/jdk8u-dev/build/macosx-x86_64-normal-server-fastdebug/images/j2sdk-image"
		return
	fi
}

build_jvmci_jdk8() {
	build_jdk8
	clone_or_update https://github.com/graalvm/graal-jvmci-8 "$BUILD_DIR/graal-jvmci-8"
	cd "$BUILD_DIR/graal-jvmci-8"
	unset JAVA_HOME
	mx --java-home "$NEW_JAVA_HOME" build
	mx --java-home "$NEW_JAVA_HOME" unittest
	echo JVMCI_JDK_HOME is `mx --java-home "$NEW_JAVA_HOME" jdkhome`
}

download_graal() {
	clone_or_update https://github.com/oracle/graal.git "$BUILD_DIR/graal"
}

test_graal() {
	clone_or_update https://github.com/graalvm/graalvm-demos "$BUILD_DIR/graalvm-demos"
	cd "$BUILD_DIR/graalvm-demos/native-list-dir"
	./build.sh
	./run.sh
}
	
clean_graal() {
	cd $BUILD_DIR/graal
	for a in compiler sdk substratevm sulong tools vm truffle ; do ( cd $a ; mx clean ; cd .. ) ; done 
}


if $DOWNLOAD_JCVMCI_JDK8 ; then
	download_jvmci_jdk8
	export JAVA_HOME=$TOOL_DIR/jvmci_jdk8/Contents/Home
else
	build_jvmci_jdk8
	cd "$BUILD_DIR/graal-jvmci-8"
	export JAVA_HOME=$(mx --java-home "$NEW_JAVA_HOME" jdkhome)
fi

echo Using JAVA_HOME=$JAVA_HOME
export PATH=$JAVA_HOME/bin:$PATH

download_graal
clean_graal
build_graal

export GRAALVM_HOME="$BUILD_DIR/graal/vm/mxbuild/darwin-amd64/GRAALVM_SVM/graalvm-svm-20.0.0-beta.02-dev"

test_graal


