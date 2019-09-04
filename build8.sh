#!/bin/bash

# define JDK and repo
JDK_BASE=jdk8u-dev

# set true to build Shanendoah, false for normal build
BUILD_SHENANDOAH=true

# set true to build javaFX, false for no javaFX
BUILD_JAVAFX=true

## release, fastdebug, slowdebug
DEBUG_LEVEL=release
DEBUG_LEVEL=slowdebug
DEBUG_LEVEL=fastdebug

### no need to change anything below this line unless something went wrong

set -e

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
SCRIPT_DIR=`pwd`
PATCH_DIR="$SCRIPT_DIR/jdk8u-patch"
popd
JDK_DIR="$BUILD_DIR/$JDK_BASE"
JDK_CONF=macosx-x86_64-normal-server-$DEBUG_LEVEL

if $BUILD_SHENANDOAH ; then 
	JDK_BASE=jdk8
	JDK_DIR="$BUILD_DIR/$JDK_BASE-shenandoah"
	JDK_REPO=http://hg.openjdk.java.net/shenandoah/$JDK_BASE
else
	JDK_REPO=http://hg.openjdk.java.net/jdk8u/$JDK_BASE
fi

if $BUILD_JAVAFX ; then
  JAVAFX_REPO=https://hg.openjdk.java.net/openjfx/8u-dev/rt
  JAVAFX_BUILD_DIR="$BUILD_DIR/jfx8"
fi

### JDK

downloadjdksrc() {
	if [ ! -d "$JDK_DIR" ]; then
		pushd "$BUILD_DIR"
		hg clone $JDK_REPO "$JDK_DIR"
		cd "$JDK_DIR"
		chmod 755 get_source.sh configure
		./get_source.sh
		popd
	else 
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
	rm -fr "$JDK_DIR/build"
	find "$JDK_DIR" -name \*.rej  -exec rm {} \; 2>/dev/null || true 
	find "$JDK_DIR" -name \*.orig -exec rm {} \; 2>/dev/null || true
}

configurejdk() {
	#if [ $XCODE_VERSION -ge 11 ] ; then
	#	DISABLE_PCH=--disable-precompiled-headers
	#fi
	pushd "$JDK_DIR"
	chmod 755 ./configure
	unset JAVA_HOME
	BOOT_JDK="$TOOL_DIR/jdk8u/Contents/Home"
	./configure --with-toolchain-type=clang \
            --with-xcode-path="$XCODE_APP" \
            --includedir="$XCODE_DEVELOPER_PREFIX/Toolchains/XcodeDefault.xctoolchain/usr/include" \
            --with-debug-level=$DEBUG_LEVEL \
            --with-boot-jdk="$BOOT_JDK" \
            --with-jtreg="$BUILD_DIR/tools/jtreg" \
            --with-freetype-include="$TOOL_DIR/freetype/include" \
            --with-freetype-lib=$TOOL_DIR/freetype/objs/.libs $DISABLE_PCH
	popd
}

buildjdk() {
	pushd "$JDK_DIR"
	make images COMPILER_WARNINGS_FATAL=false CONF=$JDK_CONF
	popd
}

testjdk() {
	pushd "$JDK_DIR"
	JT_HOME="$BUILD_DIR/tools/jtreg" make test TEST="tier1" 
	popd
}

#### Java FX

clone_javafx() {
  if [ ! -d $JAVAFX_BUILD_DIR ] ; then
    cd `dirname $JAVAFX_BUILD_DIR`
    hg clone $JAVAFX_REPO "$JAVAFX_BUILD_DIR"
    chmod 755 "$JAVAFX_BUILD_DIR/gradlew"
  fi
}

patch_javafx() {
	pushd "$JAVAFX_BUILD_DIR"
	hg import -f --no-commit "$SCRIPT_DIR/javafx8.patch"
	popd
}

revert_javafx() {
	pushd "$JAVAFX_BUILD_DIR"
	hg revert .
	popd
}

test_javafx() {
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew --info cleanTest :base:test
}

build_javafx() {
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew sdk
}

build_javafx_demos() {
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew :apps:build
}

clean_javafx() {
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew clean
    rm -fr build
}

overlay_javafx() {
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew zips
    cd "$JDK_IMAGE_DIR"
    unzip "$JAVAFX_BUILD_DIR/build/bundles/javafx-sdk-overlay.zip"
}


#### build the world

if $BUILD_JAVAFX ; then
	JAVAFX_TOOLS="ant cmake mvn" 
else
	unset JAVAFX_TOOLS
fi

. "$SCRIPT_DIR/tools.sh" "$BUILD_DIR/tools" freetype autoconf mercurial bootstrap_jdk8 webrev jtreg $JAVAFX_TOOLS

if $BUILD_JAVAFX ; then
	clone_javafx
	revert_javafx
	patch_javafx
	#clean_javafx
	build_javafx
	test_javafx
	build_javafx_demos
fi


downloadjdksrc
revertjdk
patchjdk
#cleanjdk
configurejdk
buildjdk
#testjdk

JDK_IMAGE_DIR="$JDK_DIR/build/$JDK_CONF/images/j2sdk-image"

if $BUILD_JAVAFX ; then
	WITH_JAVAFX_STR=-javafx
fi

if $BUILD_SHENANDOAH ; then
	WITH_SHENANDOAH_STR=-shenandoah
fi

overlay_javafx

# create distribution zip
pushd "$JDK_IMAGE_DIR"
zip -r $BUILD_DIR/$JDK_BASE$WITH_JAVAFX_STR$WITH_SHENANDOAH_STR.zip .
popd

