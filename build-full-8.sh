#!/bin/bash

set -x
set -e

# define toolchain
XCODE_APP=`dirname \`dirname \\\`xcode-select -p \\\`\``
XCODE_DEVELOPER_PREFIX=$XCODE_APP/Contents/Developer
CCTOOLCHAIN_PREFIX=$XCODE_APP/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
OLDPATH=$PATH
export PATH=$TOOL_PREFIX/usr/bin:$PATH
export PATH=$CCTOOLCHAIN_PREFIX/usr/bin:$PATH

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
PATCH_DIR=`pwd`
popd
TOOL_DIR=$BUILD_DIR/tools

JAVAFX_REPO=https://hg.openjdk.java.net/openjfx/jfx-dev/rt
JAVAFX_BUILD_DIR=`pwd`/javafx

clone_javafx() {
  if [ ! -d $JAVAFX_BUILD_DIR ] ; then
    cd `dirname $JAVAFX_BUILD_DIR`
    hg clone $JAVAFX_REPO "$JAVAFX_BUILD_DIR"
    chmod 755 "$JAVAFX_BUILD_DIR/gradlew"
  fi
}


build_javafx() {
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew
}

clean_javafx() {
    cd "$JAVAFX_BUILD_DIR"
    #./gradlew clean
    rm -fr build
}

build_jdk11() {
   if [ ! -f $JDK_DIR/bin/javac ] ; then
       $PATCH_DIR/build11.sh --with-import-modules=$JAVAFX_BUILD_DIR/build/modular-sdk
   fi
}
 
. $PATCH_DIR/tools.sh $TOOL_DIR ant mercurial cmake mvn bootstrap_jdk11

clone_javafx
clean_javafx
build_javafx

SCRATCH_BUILD_JAVA=true
if $SCRATCH_BUILD_JAVA ; then
   export JDK_DIR=$BUILD_DIR/jdk11u-dev/build/macosx-x86_64-normal-server-release/images/jdk
   export JAVA_HOME=$JDK_DIR
   export PATH=$JAVA_HOME/bin:$PATH
   cd $BUILD_DIR
   build_jdk11
fi

