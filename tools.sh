#!/bin/bash

# usage: . ./tools.sh tooldir [tool]...

# define toolchain
XCODE_APP=`dirname \`dirname \\\`xcode-select -p \\\`\``
XCODE_VERSION=`/usr/bin/xcodebuild -version | sed -En 's/Xcode[[:space:]]+([0-9\.]*)/\1/p' | sed s/[.][0-9]*//`
XCODE_DEVELOPER_PREFIX=$XCODE_APP/Contents/Developer
CCTOOLCHAIN_PREFIX=$XCODE_APP/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
OLDPATH=$PATH
export PATH=$TOOL_PREFIX/usr/bin:$PATH
export PATH=$CCTOOLCHAIN_PREFIX/usr/bin:$PATH
echo Using xcode version $XCODE_VERSION installed in $XCODE_APP

# define build environment
TOOL_DIR="$1"
if test ".$TOOL_DIR" = "." ; then 
	TOOL_DIR="`pwd`/tools"
fi
if test ".$DOWNLOAD_DIR" = "." ; then
	DOWNLOAD_DIR="$TOOL_DIR/downloads"
fi
if test ".$TOOL_INSTALL_ROOT" = "." ; then
	TOOL_INSTALL_ROOT="$TOOL_DIR/local"
fi
if test ".$TMP" = "." ; then
	TMP=/tmp
fi
if test ".$TMP_DIR" = "." ; then
	TMP_DIR="$TMP/$$.work"
fi

download_and_open() {
	URL="$1"
	FILE="$DOWNLOAD_DIR/`basename $URL`"
	DEST="$2"
	if ! test -f "$FILE" ; then 
		pushd "$DOWNLOAD_DIR"
		curl -O -L --insecure "$URL"
		popd
	fi
	if test -d "$DEST" ; then
		return
	fi
	rm -fr "$TMP_DIR/dno"	
	mkdir -p "$TMP_DIR/dno"	
	pushd "$TMP_DIR/dno"	
	tar -xvf "$FILE"
	mv * "$DEST"
	popd
	rm -fr "$TMP_DIR/dno"	
}

clone_or_update() {
	URL="$1"
	DEST="$2"
	if ! test -d "$DEST" ; then 
		git clone "$URL" "$DEST"
	else
		pushd "$DEST"
		git pull 
		popd
	fi	
}

build_ant() {
	download_and_open http://apache.mirror.gtcomm.net/ant/binaries/apache-ant-1.10.6-bin.tar.gz "$TOOL_DIR/ant"
}

build_autoconf() {
	if test -d "$TOOL_DIR/autoconf" ; then
		return
	fi
	download_and_open http://ftpmirror.gnu.org/autoconf/autoconf-2.69.tar.gz "$TOOL_DIR/autoconf"
	pushd "$TOOL_DIR/autoconf"
	./configure --prefix=$TOOL_INSTALL_ROOT
	make install
	popd
}

build_automake() {
	if test -d "$TOOL_DIR/automake" ; then
		return
	fi
	download_and_open http://ftp.gnu.org/gnu/automake/automake-1.16.tar.gz "$TOOL_DIR/automake"
	pushd "$TOOL_DIR/automake"
	./configure --prefix=$TOOL_INSTALL_ROOT
	make install
	popd
}

build_bison() {
	echo bison is already in macOS
}

build_cmake() {
	if test -d "$TOOL_DIR/cmake" ; then 
		return
	fi
	download_and_open https://github.com/Kitware/CMake/releases/download/v3.14.3/cmake-3.14.3-Darwin-x86_64.tar.gz "$TOOL_DIR/cmake"
}

build_libtool() {
	echo libtool is already in macOS
}

build_mvn() {
	if test -d "$TOOL_DIR/apache-maven"; then
		return
	fi
	download_and_open http://muug.ca/mirror/apache-dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz "$TOOL_DIR/apache-maven"
}

build_mx() {
    clone_or_update https://github.com/graalvm/mx.git "$TOOL_DIR/mx"
}

build_ninja() {
	clone_or_update https://github.com/ninja-build/ninja.git "$TOOL_DIR/ninja" && cd ninja
	git checkout release
	#cat README
}

build_freetype() {
	if test -d "$TOOL_DIR/freetype" ; then
		return
	fi
	download_and_open https://nongnu.freemirror.org/nongnu/freetype/freetype-2.9.tar.gz "$TOOL_DIR/freetype"
	pushd "$TOOL_DIR/freetype"
	./configure
	make
	popd
}

build_mercurial() {
	if test -f "$TOOL_DIR/mercurial/hg" ; then
		return
	fi
	download_and_open https://www.mercurial-scm.org/release/mercurial-4.9.tar.gz "$TOOL_DIR/mercurial"
	pushd "$TOOL_DIR/mercurial"
	make local
	popd
}

build_re2c() {
	clone_or_update https://github.com/skvadrik/re2c.git "$TOOL_DIR/re2c"
	cd "$TOOL_DIR/re2c"
	./autogen.sh
	mkdir builddir && cd builddir
	../configure --prefix=$TOOL_INSTALL_ROOT
	make
	make install
}

build_bootstrap_jdk8() {
	if test -d "$TOOL_DIR/jdk8u" ; then
		return
	fi
	download_and_open https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u202-b08/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz "$TOOL_DIR/jdk8u"
}

build_bootstrap_jdk10() {
	if test -d "$TOOL_DIR/jdk10u" ; then
		return
	fi
	download_and_open https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u202-b08/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz "$TOOL_DIR/jdk10u"
}

build_bootstrap_jdk11() {
	if test -d "$TOOL_DIR/jdk11u" ; then
			return
	fi
	download_and_open https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.2%2B9/OpenJDK11U-jdk_x64_mac_hotspot_11.0.2_9.tar.gz "$TOOL_DIR/jdk11u"
}

build_bootstrap_jdk12() {
	if test -d "$TOOL_DIR/jdk12u" ; then
			return
	fi
	download_and_open https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk-12%2B33/OpenJDK12U-jdk_x64_mac_hotspot_12_33.tar.gz "$TOOL_DIR/jdk12u"
}

build_make() {
	# make is already in macos, but kind of old
	if test -d "$TOOL_DIR/make-4.2.1" ; then
			return
	fi
	download_and_open "https://ftp.gnu.org/gnu/make/make-4.2.1.tar.gz" "$TOOL_DIR/make-4.2.1"
	pushd "$TOOL_DIR/make-4.2.1"
	mkdir -p "builddir" && cd "builddir"
	../configure --prefix=$TOOL_INSTALL_ROOT
	make all
	make check
	make install
	popd
}
	
build_webrev() {
	if test -f "$TOOL_DIR/webrev/webrev.ksh" ; then
		return
	fi
	pushd "$TOOL_DIR"
	mkdir -p "$TOOL_DIR/webrev"
	cd "$TOOL_DIR/webrev"
	curl -O -L https://hg.openjdk.java.net/code-tools/webrev/raw-file/tip/webrev.ksh
	chmod 755 webrev.ksh
	popd
}

build_jtreg() {
	JTREG_URL=https://ci.adoptopenjdk.net/view/Dependencies/job/jtreg/lastSuccessfulBuild/artifact/jtreg-4.2-b14.tar.gz
	if test -d "$TOOL_DIR/jtreg" ; then
			return
	fi
	download_and_open $JTREG_URL "$TOOL_DIR/jtreg"
}

junk_build_jtreg() {
	# does not work, so just download a built jtreg for now
	## requires Ant Mercurial, wget and a JDK 7 or 8
	# build_ant
	build_wget
	cd "$TOOL_DIR"
	clone_or_update http://hg.openjdk.java.net/code-tools/jtreg jtreg
	cd jtreg
	sh make/build-all.sh "$1"
}

buildtools() {
	mkdir -p "$DOWNLOAD_DIR"
	mkdir -p "$TOOL_DIR"

	for tool in $* ; do 
		echo "building $tool"
		build_$tool
		if test $tool == "bootstrap_jdk8" ; then
			export JAVA_HOME=$TOOL_DIR/jdk8u/Contents/Home
		fi
		if test $tool = "bootstrap_jdk9" ; then
		    export JAVA_HOME=$TOOL_DIR/jdk9u/Contents/Home
        	fi
		if test $tool = "bootstrap_jdk10" ; then
        	    export JAVA_HOME=$TOOL_DIR/jdk10u/Contents/Home
	        fi
		if test $tool = "bootstrap_jdk11" ; then
            	    export JAVA_HOME=$TOOL_DIR/jdk11u/Contents/Home
        	fi
		if test $tool = "bootstrap_jdk12" ; then
        	    export JAVA_HOME=$TOOL_DIR/jdk12u/Contents/Home
        	fi
	done
}

export PATH=$OLDPATH
export PATH=$TOOL_DIR/ant/bin:$PATH
export PATH=$TOOL_DIR/apache-maven/bin:$PATH
export PATH=$TOOL_DIR/cmake/CMake.app/Contents/bin:$PATH
export PATH=$TOOL_DIR/jtreg/bin:$PATH
export PATH=$TOOL_DIR/mercurial:$PATH
export PATH=$TOOL_DIR/mx:$PATH
export PATH=$TOOL_DIR/ninja:$PATH
export PATH=$TOOL_DIR/re2c/builddir/dist/bin:$PATH
export PATH=$TOOL_DIR/webrev:$PATH
export PATH=$JAVA_HOME/bin:$PATH
export PATH=$TOOL_INSTALL_ROOT/bin:$PATH
mkdir -p "$TMP_DIR"
shift
buildtools $*
rm -fr "$TMP_DIR"

