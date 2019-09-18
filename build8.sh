#!/bin/bash

# define JDK and repo
if [ "X$JDK_BASE" == "X" ] ; then
	JDK_BASE=jdk8u-dev
fi

# set true to build Shanendoah, false for normal build
if [ "X$BUILD_SHENANDOAH" == "X" ] ; then
	BUILD_SHENANDOAH=false
fi

# set true to build fromt he 8u JFR incubator repo, false for normal build
# note that only one of BUILD_SHENANDOAH or BUILD_JFR_INCUBATOR can be set.
if [ "X$BUILD_JFR_INCUBATOR" == "X" ] ; then
	BUILD_JFR_INCUBATOR=false
fi

# set true to build javaFX, false for no javaFX
if [ "X$BUILD_JAVAFX" == "X" ] ; then
	BUILD_JAVAFX=false
fi
BUILD_SCENEBUILDER=true

## release, fastdebug, slowdebug
if [ "X$DEBUG_LEVEL" == "X" ] ; then
	DEBUG_LEVEL=fastdebug
fi

### no need to change anything below this line unless something went wrong

set -e

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
SCRIPT_DIR=`pwd`
PATCH_DIR="$SCRIPT_DIR/jdk8u-patch"
TOOL_DIR="$BUILD_DIR/tools"
TMP_DIR="$TOOL_DIR/tmp"
popd
JDK_DIR="$BUILD_DIR/$JDK_BASE"
JDK_CONF=macosx-x86_64-normal-server-$DEBUG_LEVEL

if $BUILD_SHENANDOAH ; then 
	JDK_BASE=jdk8
	JDK_DIR="$BUILD_DIR/$JDK_BASE-shenandoah"
	JDK_REPO=http://hg.openjdk.java.net/shenandoah/$JDK_BASE
elif $BUILD_JFR_INCUBATOR ; then
	JDK_BASE=jdk8u-jfr-incubator
	JDK_DIR="$BUILD_DIR/$JDK_BASE-jfr-incubator"
	JDK_REPO=http://hg.openjdk.java.net/jdk8u/$JDK_BASE
else
	JDK_REPO=http://hg.openjdk.java.net/jdk8u/$JDK_BASE
fi

### JDK

downloadjdksrc() {
	if [ ! -d "$JDK_DIR" ]; then
		progress "clone $JDK_REPO to $JDK_DIR"
		pushd "$BUILD_DIR"
		hg clone $JDK_REPO "$JDK_DIR"
		cd "$JDK_DIR"
		chmod 755 get_source.sh configure
		./get_source.sh
		popd
	else 
		progress "update jdk repo"
		pushd "$JDK_DIR"
		hg pull -u 
		for a in corba hotspot jaxp jaxws jdk langtools nashorn ; do
			pushd $a
			hg pull -u
			popd
		done
		popd
	fi
}

patchjdk() {
	progress "patch jdk"
	cd "$JDK_DIR"
	patch -p1 <"$PATCH_DIR/mac-jdk8u.patch"
	for a in hotspot jdk ; do 
		cd "$JDK_DIR/$a"
		for b in "$PATCH_DIR/mac-jdk8u-$a*.patch" ; do 
			 patch -p1 <$b
		done
	done
}

revertjdk() {
	cd "$JDK_DIR"
	hg revert .
	for a in hotspot jdk ; do 
		cd "$JDK_DIR/$a"
		hg revert .
	done
}

cleanjdk() {
	progress "clean jdk"
	rm -fr "$JDK_DIR/build"
	find "$JDK_DIR" -name \*.rej  -exec rm {} \; 2>/dev/null || true 
	find "$JDK_DIR" -name \*.orig -exec rm {} \; 2>/dev/null || true
}

configurejdk() {
	progress "configure jdk"
	#if [ $XCODE_VERSION -ge 11 ] ; then
	#	DISABLE_PCH=--disable-precompiled-headers
	#fi
	pushd "$JDK_DIR"
	chmod 755 ./configure
	BOOT_JDK="$TOOL_DIR/jdk8u/Contents/Home"
	./configure --with-toolchain-type=clang \
            --with-xcode-path="$XCODE_APP" \
            --includedir="$XCODE_DEVELOPER_PREFIX/Toolchains/XcodeDefault.xctoolchain/usr/include" \
            --with-debug-level=$DEBUG_LEVEL \
            --with-conf-name=$JDK_CONF \
            --with-boot-jdk="$BOOT_JDK" \
            --with-build-number=b88 \
            --with-vendor-name="pizza" \
            --with-milestone="foo" \
            --with-update-version=99 \
            --with-jtreg="$BUILD_DIR/tools/jtreg" \
            --with-freetype-include="$TOOL_DIR/freetype/include" \
            --with-freetype-lib=$TOOL_DIR/freetype/objs/.libs $DISABLE_PCH
	popd
}

buildjdk() {
	progress "build jdk"
	pushd "$JDK_DIR"
	make images COMPILER_WARNINGS_FATAL=false CONF=$JDK_CONF
	popd
}

testjdk() {
	progress "test jdk"
	pushd "$JDK_DIR"
	JT_HOME="$BUILD_DIR/tools/jtreg" make test TEST="tier1" 
	popd
}

progress() {
	echo $1
}

#### build the world

progress "download tools"

. "$SCRIPT_DIR/tools.sh" "$BUILD_DIR/tools" freetype autoconf mercurial bootstrap_jdk8 webrev jtreg

JDK_IMAGE_DIR="$JDK_DIR/build/$JDK_CONF/images/j2sdk-image"

downloadjdksrc
revertjdk
patchjdk
cleanjdk
configurejdk
buildjdk
#testjdk

progress "create distribution zip"

if $BUILD_JAVAFX ; then
	WITH_JAVAFX_STR=-javafx
fi

if $BUILD_SHENANDOAH ; then
	WITH_SHENANDOAH_STR=-shenandoah
fi

pushd "$JDK_IMAGE_DIR"
zip -r "$BUILD_DIR/$JDK_BASE$WITH_JAVAFX_STR$WITH_SHENANDOAH_STR.zip" .
popd


if $BUILD_JAVAFX ; then
	progress "call build_javafx script"
	"$SCRIPT_DIR/build-javafx.sh" "$JDK_IMAGE_DIR"
fi

