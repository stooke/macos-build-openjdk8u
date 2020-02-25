#!/bin/bash

set -e

BUILD_LOG="LOG=debug"

if [ "X$BUILD_MODE" == "X" ] ; then
	# normal, dev, shenandoah, [jvmci, jfr eventually]
	BUILD_MODE=dev
fi

## release, fastdebug, slowdebug
if [ "X$DEBUG_LEVEL" == "X" ] ; then
	DEBUG_LEVEL=fastdebug
fi

## build directory
if [ "X$BUILD_DIR" == "X" ] ; then
	BUILD_DIR=`pwd`
fi

## add javafx to build at end
if [ "X$BUILD_JAVAFX" == "X" ] ; then
	BUILD_JAVAFX=true
fi
BUILD_SCENEBUILDER=$BUILD_JAVAFX

### no need to change anything below this line unless something went wrong

set_os() {
	IS_LINUX=false
	if [ "`uname`" = "Linux" ] ; then
		IS_LINUX=true
	fi
	IS_DARWIN=false
	if [ "`uname`" = "Darwin" ] ; then
		IS_DARWIN=true
	fi
}

set_os

if [ "$BUILD_MODE" == "normal" ] ; then
	JDK_BASE=jdk8u
	BUILD_MODE=dev
	JDK_REPO=http://hg.openjdk.java.net/jdk8u/$JDK_BASE
	JDK_DIR="$BUILD_DIR/$JDK_BASE"
elif [ "$BUILD_MODE" == "dev" ] ; then
	JDK_BASE=jdk8u-dev
	BUILD_MODE=dev
	JDK_REPO=http://hg.openjdk.java.net/jdk8u/$JDK_BASE
	JDK_DIR="$BUILD_DIR/$JDK_BASE"
elif [ "$BUILD_MODE" == "shenandoah" ] ; then
	JDK_BASE=jdk8
	BUILD_MODE=dev
	JDK_REPO=http://hg.openjdk.java.net/shenandoah/$JDK_BASE
	JDK_DIR="$BUILD_DIR/$JDK_BASE-shenandoah"
elif [ "$BUILD_MODE" == "jvmci" ] ; then
# this doesn't work yet
	echo "BUILDMODE=jvmci is not yet supported by this script"
	JDK_BASE=jdk8u-dev
	BUILD_MODE=dev
	JDK_REPO=http://hg.openjdk.java.net/jdk8u/$JDK_BASE
	JDK_DIR="$BUILD_DIR/$JDK_BASE-jvmci"
elif [ "$BUILD_MODE" == "jfr" ] ; then
	JDK_BASE=jdk8u-jfr-incubator
	BUILD_MODE=dev
	JDK_REPO=http://hg.openjdk.java.net/jdk8u/$JDK_BASE
	JDK_DIR="$BUILD_DIR/$JDK_BASE"
fi

# define build environment
pushd `dirname $0`
SCRIPT_DIR=`pwd`
PATCH_DIR="$SCRIPT_DIR/jdk8u-patch"
TOOL_DIR="$BUILD_DIR/tools"
TMP_DIR="$TOOL_DIR/tmp"
popd

if $IS_DARWIN ; then
	JDK_CONF=macosx-x86_64-normal-server-$DEBUG_LEVEL
else
	JDK_CONF=linux-x86_64-normal-server-$DEBUG_LEVEL
fi

### JDK

downloadjdksrc() {
	if [ ! -d "$JDK_DIR" ]; then
		progress "clone $JDK_REPO to $JDK_DIR"
		pushd "$BUILD_DIR"
		hg clone $JDK_REPO "$JDK_DIR"
		popd
	fi
	pushd "$JDK_DIR"
	chmod 755 get_source.sh configure
	./get_source.sh
	popd
	print_jdk_repo_id
}

print_jdk_repo_id() {
	pushd "$JDK_DIR"
	progress "JDK base repo: `hg id`"
	for a in corba hotspot jaxp jaxws jdk langtools nashorn ; do
		pushd $a
		progress "JDK $a repo: `hg id`"
		popd
	done
	popd
}

applypatch() {
	cd "$JDK_DIR/$1"
	echo "applying $1 $2"
	patch -p1 <$2
}

patchjdk() {
	progress "patch jdk"
	applypatch . "$PATCH_DIR/mac-jdk8u.patch"
	for a in hotspot jdk ; do 
		for b in "$PATCH_DIR/mac-jdk8u-$a*.patch" ; do 
			applypatch $a "$b"
		done
	done
	for a in hotspot ; do 
		for b in "$PATCH_DIR/linux-jdk8u-$a*.patch" ; do 
			applypatch $a "$b"
		done
	done
	# fix genSocketOptionRegistry build error on 10.8
	applypatch jdk     "$PATCH_DIR/8152545-jdk-jdk8u.patch"
	# fix concurrency crash
	applypatch hotspot "$PATCH_DIR/8181872-hotspot-jdk8u.patch"
	applypatch hotspot "$PATCH_DIR/01-8062370-hotspot-jdk8u.patch"
	applypatch hotspot "$PATCH_DIR/02-8060721-hotspot-jdk8u.patch"
	applypatch hotspot "$PATCH_DIR/8138820-hotspot-jdk8u.patch"
}

revertjdk() {
	cd "$JDK_DIR"
	hg revert .
	for a in hotspot jdk ; do 
		cd "$JDK_DIR/$a"
		hg revert .
	done
	cd "$JDK_DIR"
	find . -name \*.rej -exec rm {} \; -print
 	find . -name \*.orig -exec rm {} \; -print
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
	unset DARWIN_CONFIG
	if $IS_DARWIN ; then
		BOOT_JDK="$TOOL_DIR/jdk8u/Contents/Home"
		DARWIN_CONFIG="--with-toolchain-type=clang \
            --with-xcode-path="$XCODE_APP" \
            --includedir="$XCODE_DEVELOPER_PREFIX/Toolchains/XcodeDefault.xctoolchain/usr/include" \
            --with-boot-jdk="$BOOT_JDK""
	fi
	BUILD_VERSION_CONFIG="--with-build-number=b88 \
            --with-vendor-name="pizza" \
            --with-milestone="foo" \
            --with-update-version=99"
	./configure $DARWIN_CONFIG $BUILD_VERSION_CONFIG \
            --with-debug-level=$DEBUG_LEVEL \
            --with-conf-name=$JDK_CONF \
            --with-jtreg="$BUILD_DIR/tools/jtreg" \
            --with-freetype-include="$TOOL_DIR/freetype/include" \
            --with-freetype-lib=$TOOL_DIR/freetype/objs/.libs $DISABLE_PCH
	popd
}

buildjdk() {
	progress "build jdk"
	pushd "$JDK_DIR"
	make images $BUILD_LOG COMPILER_WARNINGS_FATAL=false CONF=$JDK_CONF
	if $IS_DARWIN ; then
		# seems the path handling has changed; use rpath instead of hardcoded path
		find  "$JDK_DIR/build/$JDK_CONF/images" -type f -name libfontmanager.dylib -exec install_name_tool -change /usr/local/lib/libfreetype.6.dylib @rpath/libfreetype.dylib.6 {} \; -print
	fi
	popd
}

testjdk() {
	progress "test jdk"
	pushd "$JDK_DIR"
	JT_HOME="$BUILD_DIR/tools/jtreg" make test TEST="tier1" 
	#JT_HOME="$BUILD_DIR/tools/jtreg" make test TEST="hotspot_tier1"
	#JT_HOME="$BUILD_DIR/tools/jtreg" make test TEST="jdk_tier1"
	popd
}


progress() {
	echo $1
}

#### build the world

progress "download tools"

set_os

if $IS_DARWIN ; then
	. "$SCRIPT_DIR/tools.sh" "$BUILD_DIR/tools" freetype autoconf mercurial bootstrap_jdk8 webrev jtreg
else
	. "$SCRIPT_DIR/tools.sh" "$BUILD_DIR/tools" freetype webrev jtreg
fi

JDK_IMAGE_DIR="$JDK_DIR/build/$JDK_CONF/images/j2sdk-image"

downloadjdksrc
print_jdk_repo_id
#revertjdk
patchjdk
#cleanjdk
configurejdk
buildjdk
testjdk

progress "create distribution zip"

if $BUILD_JAVAFX ; then
	WITH_JAVAFX_STR=-javafx
fi

ZIP_NAME="$BUILD_DIR/jdk8u$BUILD_MODE$WITH_JAVAFX_STR.zip"

if $BUILD_JAVAFX ; then
	progress "call build_javafx script"
	"$SCRIPT_DIR/build-javafx.sh" "$JDK_IMAGE_DIR" "$ZIP_NAME"
else
	pushd "$JDK_IMAGE_DIR"
	zip -r "$ZIP_NAME" .
	popd
fi


