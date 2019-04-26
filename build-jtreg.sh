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

build_autoconf() {
	cd "$DOWNLOAD_DIR"
	curl -O -L http://ftpmirror.gnu.org/autoconf/autoconf-2.69.tar.gz
	cd "$TOOL_DIR"
	tar -xzf "$DOWNLOAD_DIR/autoconf-2.69.tar.gz"
	cd autoconf-2.69
	./configure --prefix=`pwd`
	make install
}

build_mercurial() {
	cd "$DOWNLOAD_DIR"
	curl -O https://www.mercurial-scm.org/release/mercurial-4.9.tar.gz
	cd "$TOOL_DIR"
	tar -xvf "$DOWNLOAD_DIR/mercurial-4.9.tar.gz"
	cd mercurial-4.9
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

build_ant() {
	cd "$DOWNLOAD_DIR"
	curl -O -L https://www.apache.org/dist/ant/binaries/apache-ant-1.10.5-bin.tar.gz
	cd "$TOOL_DIR"
	tar -xvf "$DOWNLOAD_DIR/apache-ant-1.10.5-bin.tar.gz"
}

build_jtreg() {
	## requires Ant Mercurial, wget and a JDK 7 or 8
	# build_ant
	build_wget
	cd "$TOOL_DIR"
	hg clone http://hg.openjdk.java.net/code-tools/jtreg
	cd jtreg
	sh make/build-all.sh "$1"
}

buildtools() {
	mkdir -p "$DOWNLOAD_DIR"
	mkdir -p "$TOOL_DIR"

	for tool in autoconf mercurial bootstrap_jdk8 webrev ; do 
		echo "building $tool"
		build_$tool
	done
}

export PATH=$OLDPATH
export JAVA_HOME=$TOOL_DIR/jdk8u202-b08/Contents/Home
export PATH=$TOOL_DIR/autoconf-2.69/bin:$PATH
export PATH=$TOOL_DIR/mercurial-4.9:$PATH
export PATH=$TOOL_DIR/apache-ant-1.10.5-bin/bin:$PATH
export PATH=$TOOL_DIR/webrev:$PATH
export PATH=$TOOL_DIR/jtreg:$PATH
export PATH=$JAVA_HOME/bin:$PATH

buildtools
build_jtreg $JAVA_HOME


