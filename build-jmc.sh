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

JAVA_HOME=/Users/stooke/dev/ojdk/tools/jdk8u202-b08/Contents/Home
export JAVA_HOME

JMC_REPO=https://hg.openjdk.java.net/jmc/jmc/
JMC_BUILD_DIR=`pwd`/jmc

HG=$TOOL_DIR/mercurial-4.9/hg
MVN=$TOOL_DIR/apache-maven-3.6.1/bin/mvn

clone_jmc() {
    cd `dirname $JMC_BUILD_DIR`
    $HG clone $JMC_REPO $JMC_BUILD_DIR
}

download_mvn() {
    cd "$DOWNLOAD_DIR"
    curl -O http://muug.ca/mirror/apache-dist/maven/maven-3/3.6.1/binaries/apache-maven-3.6.1-bin.tar.gz
    cd "$TOOL_DIR"
	tar -xvf "$DOWNLOAD_DIR/apache-maven-3.6.1-bin.tar.gz"
}

start_jmc_background() {
    cd "$JMC_BUILD_DIR"
    cd releng/third-party
    $MVN p2:site
    $MVN jetty:run&
}

build_jmc() {
    cd "$JMC_BUILD_DIR"
    cd core
    $MVN clean install
    cd ..
    $MVN package
}

clean_jmc() {
    cd "$JMC_BUILD_DIR"
    $MVN clean
    cd core
    $MVN clean
    rm -fr $HOME/.m2/repository
}

download_mvn
clone_jmc
#clean_jmc
start_jmc_background
sleep 5
build_jmc

