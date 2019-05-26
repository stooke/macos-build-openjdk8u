#!/bin/bash

set -x

# define toolchain
XCODE_APP=`dirname \`dirname \\\`xcode-select -p \\\`\``
XCODE_DEVELOPER_PREFIX=$XCODE_APP/Contents/Developer
CCTOOLCHAIN_PREFIX=$XCODE_APP/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
OLDPATH=$PATH
export PATH=$TOOL_PREFIX/usr/bin:$PATH
export PATH=$CCTOOLCHAIN_PREFIX/usr/bin:$PATH

# define buuld environment
BUILD_DIR=`pwd`
pushd `dirname $0`
PATCH_DIR=`pwd`
popd
TOOL_DIR=$BUILD_DIR/tools
JDK_DIR=$BUILD_DIR/$JDKBASE

JAVAFX_REPO=https://hg.openjdk.java.net/openjfx/jfx-dev/rt
JAVAFX_BUILD_DIR=`pwd`/javafx

clone_javafx() {
    cd `dirname $JAVAFX_BUILD_DIR`
    hg clone $JAVAFX_REPO "$JAVAFX_BUILD_DIR"
    chmod 755 "$JAVAFX_BUILD_DIR/gradlew"
}

build_javafx() {
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew
}

clean_javafx() {
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew clean
}

. $PATCH_DIR/tools.sh $TOOL_DIR mercurial cmake mvn bootstrap_jdk11

clone_javafx
clean_javafx
build_javafx

