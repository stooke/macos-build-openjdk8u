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
DOWNLOAD_DIR=$BUILD_DIR/tools/downloads
JDK_DIR=$BUILD_DIR/$JDKBASE
JAVA_HOME=/Users/stooke/dev/ojdk/tools/jdk-11.0.2+9/Contents/Home
export JAVA_HOME
export JDK_HOME=$JAVA_HOME

JAVAFX_REPO=https://hg.openjdk.java.net/openjfx/jfx-dev/rt
JAVAFX_BUILD_DIR=`pwd`/javafx

HG=$TOOL_DIR/mercurial-4.9/hg
MVN=$TOOL_DIR/apache-maven-3.6.1/bin/mvn

clone_javafx() {
    cd `dirname $JAVAFX_BUILD_DIR`
    $HG clone $JAVAFX_REPO "$JAVAFX_BUILD_DIR"
    chmod 755 "$JAVAFX_BUILD_DIR/gradlew"
}

download_cmake() {
    cd "$DOWNLOAD_DIR"
    curl -L -O https://github.com/Kitware/CMake/releases/download/v3.14.3/cmake-3.14.3-Darwin-x86_64.tar.gz
    cd "$TOOL_DIR"
    tar -xvf "$DOWNLOAD_DIR/cmake-3.14.3-Darwin-x86_64.tar.gz"
}

download_mvn() {
    cd "$DOWNLOAD_DIR"
    curl -L -O http://muug.ca/mirror/apache-dist/maven/maven-3/3.6.1/binaries/apache-maven-3.6.1-bin.tar.gz
    cd "$TOOL_DIR"
	tar -xvf "$DOWNLOAD_DIR/apache-maven-3.6.1-bin.tar.gz"
}

build_javafx() {
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew
}

clean_javafx() {
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew clean
}

PATH=$TOOL_DIR/apache-maven-3.6.1/bin:$PATH
PATH=$TOOL_DIR/cmake-3.14.3-Darwin-x86_64/CMake.app/Contents/bin:$PATH
PATH=$JAVA_HOME/bin:$PATH

download_cmake
download_mvn
clone_javafx
clean_javafx
build_javafx

