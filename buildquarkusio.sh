#!/bin/bash

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
PATCH_DIR=`pwd`
popd
TOOL_DIR=$BUILD_DIR/tools
. $PATCH_DIR/tools.sh "$TOOL_DIR" mx maven bootstrap_jdk8

git clone https://github.com/quarkusio/quarkus.git

cd quarkus
./mvnw clean install

