#!/bin/bash

# from https://github.com/apple/swift

# define repos
SWIFT_REPO_URL=https://github.com/apple/swift.git


# define build environment
BUILD_DIR=`pwd`/swift-source
mkdir -p "$BUILD_DIR"

pushd `dirname $0`
PATCH_DIR=`pwd`
popd

download_swift_src() {
	clone_or_update $SWIFT_REPO_URL "$BUILD_DIR/swift"
	cd "$BUILD_DIR"
	./swift/utils/update-checkout --clone
}

build_swift() {
	cd "$BUILD_DIR"
	./swift/utils/build-script --release-debuginfo
}

test_swift() {
	cd "$BUILD_DIR"
}

. $PATCH_DIR/tools.sh "$BUILD_DIR/../tools" cmake ninja re2c
download_swift_src
#configure_swift
time build_swift
#time test_swift
