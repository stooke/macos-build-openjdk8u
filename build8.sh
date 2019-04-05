#!/bin/bash

set -x

# define toolchain
XCODE_APP=/Applications/Xcode.app
XCODE_DEVELOPER_PREFIX=$XCODE_APP/Contents/Developer
CCTOOLCHAIN_PREFIX=$XCODE_APP/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
OLDPATH=$PATH
export PATH=$TOOL_PREFIX/usr/bin:$PATH
export PATH=$CCTOOLCHAIN_PREFIX/usr/bin:$PATH

# define JDK and repo
JDKBASE=jdk8u-dev
DEBUG_LEVEL=release
DEBUG_LEVEL=slowdebug
## release, fastdebug, slowdebug

# define buuld environment
BUILD_DIR=`pwd`
pushd `dirname $0`
PATCH_DIR=`pwd`
popd
TOOL_DIR=$BUILD_DIR/tools
DOWNLOAD_DIR=$BUILD_DIR/tools/downloads
JDK_DIR=$BUILD_DIR/$JDKBASE

build_autoconf() {
	cd "$DOWNLOAD_DIR"
	curl -O -L http://ftpmirror.gnu.org/autoconf/autoconf-2.69.tar.gz
	cd "$TOOL_DIR"
	tar -xzf "$DOWNLOAD_DIR/autoconf-2.69.tar.gz"
	cd autoconf-2.69
	./configure --prefix=`pwd`
	make install
}

build_freetype() {
	cd "$DOWNLOAD_DIR"
	curl -O https://nongnu.freemirror.org/nongnu/freetype/freetype-2.9.tar.gz
	cd "$TOOL_DIR"
	tar -xvf "$DOWNLOAD_DIR/freetype-2.9.tar.gz"
	cd freetype-2.9
	./configure
	make
}

build_mercurial() {
	cd "$DOWNLOAD_DIR"
	curl -O https://www.mercurial-scm.org/release/mercurial-4.9.tar.gz
	cd "$TOOL_DIR"
	tar -xvf "$DOWNLOAD_DIR/mercurial-4.9.tar.gz"
	cd mercurial-4.9/
	make local
}

build_bootstrap_jdk8() {
	cd "$DOWNLOAD_DIR"
	curl -O -L https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u202-b08/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz
	cd "$TOOL_DIR"
	tar -xvf "$DOWNLOAD_DIR/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz"
}

build_bootstrap_jdk10() {
	cd "$DOWNLOAD_DIR"
	curl -O -L https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u202-b08/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz
	cd "$TOOL_DIR"
	tar -xvf "$DOWNLOAD_DIR/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz"
}

buildtools() {
	mkdir -p "$DOWNLOAD_DIR"
	mkdir -p "$TOOL_DIR"

	for tool in freetype autoconf mercurial bootstrap_jdk8 ; do 
		echo "building $tool"
		build_$tool
	done
}

export PATH=$OLDPATH
export JAVA_HOME=$TOOL_DIR/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08/Contents/Home
export PATH=$TOOL_DIR/autoconf-2.69/bin:$PATH
export PATH=$TOOL_DIR/mercurial-4.9:$PATH
export PATH=$JAVA_HOME/bin:$PATH

downloadjdksrc() {
	cd $BUILD_DIR
	hg clone http://hg.openjdk.java.net/jdk8u/jdk8u-dev $JDK_DIR
	cd $JDK_DIR
	chmod 755 get_source.sh configure
	./get_source.sh
	hg revert .
}

patchjdk() {
	cd $JDK_DIR
	hg revert .
	hg import --no-commit $PATCH_DIR/mac-jdk8u.patch
	for a in hotspot jdk ; do 
		cd $JDK_DIR/$a
		hg revert .
		hg import --no-commit $PATCH_DIR/mac-jdk8u-$a.patch
	done
}

configurejdk() {
	cd $JDK_DIR
	chmod 755 ./configure
	./configure --with-toolchain-type=clang \
            --with-xcode-path=$XCODE_APP \
            --includedir=$XCODE_DEVELOPER_PREFIX/Toolchains/XcodeDefault.xctoolchain/usr/include \
            --with-debug-level=$DEBUG_LEVEL \
            --with-boot-jdk=$TOOL_DIR/jdk8u202-b08/Contents/Home \
            --with-freetype-include=$TOOL_DIR/freetype-2.9/include \
            --with-freetype-lib=$TOOL_DIR/freetype-2.9/objs/.libs
}

buildjdk() {
	cd $JDK_DIR
	make images COMPILER_WARNINGS_FATAL=false CONF=macosx-x86_64-normal-server-$DEBUG_LEVEL
}

buildtools
downloadjdksrc
patchjdk
configurejdk
buildjdk

