#!/bin/bash

set -x
set -e

# build options
SCRATCH_BUILD_JAVA=true
TARGET_JDK8=true

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
PATCH_DIR=`pwd`
popd
TOOL_DIR=$BUILD_DIR/tools
if ! $TARGET_JDK8 ; then
  TARGET_JDK11=$SCRATCH_BUILD_JAVA
else
  TARGET_JDK11=false
fi

if $TARGET_JDK8 ; then
  JAVAFX_REPO=https://hg.openjdk.java.net/openjfx/8u-dev/rt
  JAVAFX_BUILD_DIR=`pwd`/jfx8
fi


if $TARGET_JDK11 ; then
  JAVAFX_REPO=https://hg.openjdk.java.net/openjfx/jfx-dev/rt
  JAVAFX_BUILD_DIR=`pwd`/jfx11
fi


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

build_jdk8() {
   JDK_DIR=$BUILD_DIR/jdk8u-dev/build/macosx-x86_64-normal-server-fastdebug/images/j2sdk-image
   if [ ! -f $JDK_DIR/bin/javac ] ; then
       cd $BUILD_DIR
       $PATCH_DIR/build8.sh 
   fi
   cp $JAVAFX_BUILD_DIR/build/sdk/lib/* $JDK_DIR/jre/lib/ext
}
 
build_jdk11() {
   JDK_DIR=$BUILD_DIR/jdk11u-dev/build/macosx-x86_64-normal-server-release/images/jdk
   if [ ! -f $JDK_DIR/bin/javac ] ; then
       cd $BUILD_DIR
       $PATCH_DIR/build11.sh --with-import-modules=$JAVAFX_BUILD_DIR/build/modular-sdk
   fi
}
 
if $TARGET_JDK8 ; then
  . $PATCH_DIR/tools.sh $TOOL_DIR ant mercurial cmake mvn bootstrap_jdk8
else
  . $PATCH_DIR/tools.sh $TOOL_DIR ant mercurial cmake mvn bootstrap_jdk11
fi 

clone_javafx
clean_javafx
build_javafx

if $SCRATCH_BUILD_JAVA ; then
   if $TARGET_JDK8 ; then
      build_jdk8
   else
      build_jdk11
   fi
fi

