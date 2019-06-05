#!/bin/bash

set -x

# define buuld environment
BUILD_DIR=`pwd`
pushd `dirname $0`
PATCH_DIR=`pwd`
popd
TOOL_DIR=$BUILD_DIR/tools
JDK_DIR=$BUILD_DIR/$JDKBASE

# version is either jmc or jmc7
JMC_VERSION=jmc7
JMC_REPO=https://hg.openjdk.java.net/jmc/$JMC_VERSION
JMC_BUILD_DIR=`pwd`/$JMC_VERSION

JMC_JDK_VERSION=8

clone_jmc() {
    cd `dirname $JMC_BUILD_DIR`
    if [ ! -d "$JMC_BUILD_DIR" ] ; then 
    	hg clone $JMC_REPO $JMC_BUILD_DIR
    else
       	cd "$JMC_BUILD_DIR"
       	hg pull -u
    fi
}

start_jmc_background() {
    cd "$JMC_BUILD_DIR"
    cd releng/third-party
    mvn p2:site
    mvn jetty:run&
}

build_jmc() {
    cd "$JMC_BUILD_DIR"
    cd core
    #mvn clean install
    mvn install
    cd ..
    mvn package
}

clean_jmc() {
    cd "$JMC_BUILD_DIR"
    mvn clean
    cd core
    mvn clean
    #rm -fr $HOME/.m2/repository
}

. $PATCH_DIR/tools.sh $TOOL_DIR mvn mercurial bootstrap_jdk$JMC_JDK_VERSION

clone_jmc
#clean_jmc
start_jmc_background
sleep 5
build_jmc
