#!/bin/bash

export BUILD_JDK_HOME="$1"
export JDK_HOME="$BUILD_JDK_HOME"
export JAVA_HOME="$BUILD_JDK_HOME"

### no need to change anything below this line unless something went wrong

set -e

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
SCRIPT_DIR=`pwd`
PATCH_DIR="$SCRIPT_DIR/jfx8-patch"
TOOL_DIR="$BUILD_DIR/tools"
TMP_DIR="$TOOL_DIR/tmp"
popd

# remote repo URL
JAVAFX_REPO=https://hg.openjdk.java.net/openjfx/8u-dev/rt

# local repo directory
JAVAFX_BUILD_DIR="$BUILD_DIR/jfx8"

# where this build wil put a new JDK with javaFX
NEW_JDK_DIR="$TMP_DIR/jdk8ujfx"

clone_javafx() {
  if [ ! -d $JAVAFX_BUILD_DIR ] ; then
    progress "clone javafx repo"
    cd `dirname $JAVAFX_BUILD_DIR`
    hg clone $JAVAFX_REPO "$JAVAFX_BUILD_DIR"
    chmod 755 "$JAVAFX_BUILD_DIR/gradlew"
  fi
}

patch_javafx() {
	progress "patch javafx with javafx8.patch"
	pushd "$JAVAFX_BUILD_DIR"
	hg import --no-commit "$1"
	popd
}

revert_javafx() {
	pushd "$JAVAFX_BUILD_DIR"
	hg revert .
	popd
}

test_javafx() {
    progress "test javafx"
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew --info cleanTest :base:test
}

build_javafx() {
    progress "build javafx"
    cd "$JAVAFX_BUILD_DIR"
    #./gradlew sdk
    ./gradlew -PCOMPILE_WEBKIT=true -PCOMPILE_MEDIA=true sdk
}

build_javafx_demos() {
    progress "build javafx demos"
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew :apps:build
}

clean_javafx() {
    progress "clean javafx"
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew clean
    rm -fr build
}

save_jdk() {
	progress "move JDK to temp location"
## save off the new jdk with javafx
	mkdir -p "`dirname $2`"
	rm -fr "$2"
	cp -r "$1" "$2"
	export JAVA_HOME="$2"
	export JDK_HOME="$JAVA_HOME"
	rm -f "$JAVA_HOME/jre/lib/ext/jfxrt.jar"
	export PATH="$JAVA_HOME/bin:$PATH"
}

overlay_javafx() {
    progress "overlay javafx on top of $1"
    cd "$JAVAFX_BUILD_DIR"
    ./gradlew -PCOMPILE_WEBKIT=true -PCOMPILE_MEDIA=true zips
    cd "$1"
    unzip -o "$JAVAFX_BUILD_DIR/build/bundles/javafx-sdk-overlay.zip"
}

add_scenerbuilder() {
	# add scenebuilder jars
	mkdir -p "$NEW_JDK_DIR/scenebuilder"
	cp "$JAVAFX_BUILD_DIR/apps/scenebuilder/SceneBuilderApp/dist/"* "$NEW_JDK_DIR/scenebuilder"
	cp "$JAVAFX_BUILD_DIR/apps/scenebuilder/SceneBuilderKit/dist/"* "$NEW_JDK_DIR/scenebuilder"
	cd "$NEW_JDK_DIR/scenebuilder"
	mkdir -p "$TMP_DIR/a"
	cd "$TMP_DIR/a"
	unzip -o "$NEW_JDK_DIR/scenebuilder/SceneBuilderKit.jar"
	unzip -o "$NEW_JDK_DIR/scenebuilder/SceneBuilderApp.jar"
	zip -r "$NEW_JDK_DIR/scenebuilder/scenebuilder.jar" .
	cd "$BUILD_DIR"
	rm -fr "$TMP_DIR/a"
}

progress() {
	echo $1
}

#### build the world

progress "download tools"

. "$SCRIPT_DIR/tools.sh" "$BUILD_DIR/tools" autoconf mercurial webrev jtreg ant cmake mvn

progress "first attempt to build javafx"

if true ; then
save_jdk "$BUILD_JDK_HOME" "$NEW_JDK_DIR"
clone_javafx
revert_javafx
patch_javafx "$PATCH_DIR/javafx8-pass1.patch"
#clean_javafx
build_javafx
#test_javafx
#build_javafx_demos
fi

progress "overlay javafx on top of new jdk - pass 1"
overlay_javafx "$NEW_JDK_DIR"

revert_javafx
patch_javafx "$PATCH_DIR/javafx8-pass2a.patch"
#clean_javafx
rm -f "$NEW_JDK_DIR/jre/lib/ext/jfxrt.jar"
build_javafx
progress "overlay javafx on top of new jdk - pass 2"
overlay_javafx "$NEW_JDK_DIR"
add_scenerbuilder

progress "create distribution zip"

WITH_JAVAFX_STR=-javafx

if $BUILD_SHENANDOAH ; then
	WITH_SHENANDOAH_STR=-shenandoah
fi

pushd "$NEW_JDK_DIR"
zip -r "$BUILD_DIR/new-$JDK_BASE$WITH_JAVAFX_STR$WITH_SHENANDOAH_STR.zip" .
popd

