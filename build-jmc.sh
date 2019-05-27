#!/bin/bash

echo "**** doesn't work yet****"
return 

set -x

# define buuld environment
BUILD_DIR=`pwd`
pushd `dirname $0`
PATCH_DIR=`pwd`
popd
TOOL_DIR=$BUILD_DIR/tools
JDK_DIR=$BUILD_DIR/$JDKBASE

JMC_REPO=https://hg.openjdk.java.net/jmc/jmc/
JMC_BUILD_DIR=`pwd`/jmc

clone_jmc() {
    cd `dirname $JMC_BUILD_DIR`
    hg clone $JMC_REPO $JMC_BUILD_DIR
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

. $PATCH_DIR/tools.sh $TOOL_DIR mvn mercurial bootstrap_jdk8
clone_jmc
#clean_jmc
start_jmc_background
sleep 5
build_jmc

