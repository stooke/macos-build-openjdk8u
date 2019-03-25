#!/bin/bash

set -x

BUILD_DIR=`pwd`
JDKBASE=jdk8u-dev

DEBUG_LEVEL=release
## release, fastdebug, slowdebug

TOOL_DIR=$BUILD_DIR/tools
JDK_DIR=$BUILD_DIR/$JDKBASE

mkdir -p $TOOL_DIR/downloads

cd $TOOL_DIR
curl -O -L http://ftpmirror.gnu.org/autoconf/autoconf-2.69.tar.gz
tar -xzf autoconf-2.69.tar.gz
cd autoconf-2.69
./configure --prefix=`pwd`
make install

cd $TOOL_DIR
curl -O https://nongnu.freemirror.org/nongnu/freetype/freetype-2.9.tar.gz
tar -xvf freetype-2.9.tar.gz
cd freetype-2.9
./configure
make

cd $TOOL_DIR
curl -O https://www.mercurial-scm.org/release/mercurial-4.9.tar.gz
tar -xvf mercurial-4.9.tar.gz
cd mercurial-4.9/
make local

cd $TOOL_DIR
curl -O -L https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u202-b08/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz
tar -xvf OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz

mv $TOOL_DIR/*.gz $TOOL_DIR/downloads

export JAVA_HOME=$TOOL_DIR/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08/Contents/Home
export PATH=$TOOL_DIR/autoconf-2.69/bin:$PATH
export PATH=$TOOL_DIR/mercurial-4.9:$PATH
export PATH=$JAVA_HOME/bin:$PATH

cd $BUILD_DIR
hg clone http://hg.openjdk.java.net/jdk8u/jdk8u-dev $JDK_DIR
cd $JDK_DIR
chmod 755 get_source.sh configure
./get_source.sh
hg revert .

PATCH_DIR=$TOOL_DIR/patches
git clone https://github.com/stooke/jdk8u-xcode10.git $PATCH_DIR

cd $JDK_DIR
hg import --no-commit $PATCH_DIR/mac-jdk8u.patch
cd $JDK_DIR/hotspot
hg import --no-commit $PATCH_DIR/mac-jdk8u-hotspot.patch
cd $JDK_DIR/jdk
hg import --no-commit $PATCH_DIR/mac-jdk8u-jdk.patch

cd $JDK_DIR
chmod 755 ./configure
./configure --with-toolchain-type=clang \
            --with-debug-level=$DEBUG_LEVEL \
            --with-boot-jdk=$TOOL_DIR/jdk8u202-b08/Contents/Home \
            --with-freetype-include=$TOOL_DIR/freetype-2.9/include \
            --with-freetype-lib=$TOOL_DIR/freetype-2.9/objs/.libs

make images COMPILER_WARNINGS_FATAL=false CONF=macosx-x86_64-normal-server-$DEBUG_LEVEL

