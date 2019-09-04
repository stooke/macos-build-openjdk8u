#!/bin/bash

set -x

# define buuld environment
BUILD_DIR=`pwd`
pushd `dirname $0`
SCRIPT_DIR=`pwd`
popd
TOOL_DIR="$BUILD_DIR/tools"
JDK_DIR="$BUILD_DIR/jdk8-shenandoah/build/macosx-x86_64-normal-server-fastdebug/images/j2sdk-image"

# version is either jmc or jmc7
JMC_VERSION=jmc7
JMC_REPO=https://hg.openjdk.java.net/jmc/$JMC_VERSION
JMC_BUILD_DIR="$BUILD_DIR/$JMC_VERSION"

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

. "$SCRIPT_DIR/tools.sh" "$TOOL_DIR" mvn mercurial bootstrap_jdk$JMC_JDK_VERSION

export JDK_HOME="$JDK_DIR"
export PATH="$JDK_HOME/bin:$PATH"
clone_jmc
#clean_jmc
start_jmc_background
sleep 5
build_jmc
