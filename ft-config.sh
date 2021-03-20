#!/bin/bash

set -x

XCODE_APP=/Applications/Xcode.app
IOS_SDK_PATH="$XCODE_APP/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
MACOS_SDK_PATH="$XCODE_APP/Contents/Developer/Platforms/MacOSX.platform//Developer/SDKs/MacOSX.sdk"
SDK_PATH="$MACOS_SDK_PATH"

./configure  "--prefix=`pwd`/../local" --host=arm-apple-darwin --enable-static=yes  "CFLAGS=-arch arm64 -pipe -std=c99 -O2" "LDFLAGS=-arch arm64"


#./configure  "--prefix=`pwd`/../local" --host=arm-apple-darwin --enable-static=yes  "CFLAGS=-arch arm64 -pipe -std=c99 -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -I$SDK_PATH/usr/include -I$SDK_PATH/usr/include/libxml2/" "LDFLAGS=-arch arm64"
#./configure --without-zlib --without-png --without-bzip2 "--prefix=`pwd`/../local" --host=arm-apple-darwin --enable-static=yes  "CFLAGS=-arch arm64 -pipe -std=c99 -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -I$SDK_PATH/usr/include -I$SDK_PATH/usr/include/libxml2/" "AR=$XCODE_APP/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar" "LDFLAGS=-arch arm64 -isysroot $SDK_PATH"

# this works for static
#./configure --without-zlib --without-png --without-bzip2 "--prefix=`pwd`/../local" --host=arm-apple-darwin --enable-static=yes --enable-shared=no "CC=$XCODE_APP/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang" "CFLAGS=-arch arm64 -pipe -std=c99 -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -I$SDK_PATH/usr/include -I$SDK_PATH/usr/include/libxml2/ -isysroot $SDK_PATH" "AR=$XCODE_APP/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar" "LDFLAGS=-arch arm64 -isysroot $SDK_PATH"

# this for iOS
#./configure --without-zlib --without-png --without-bzip2 "--prefix=`pwd`/../local" --host=arm-apple-darwin --enable-static=yes --enable-shared=no "CC=$XCODE_APP/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang" "CFLAGS=-arch arm64 -pipe -std=c99 -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=8.0 -I$SDK_PATH/usr/include -I$SDK_PATH/usr/include/libxml2/ -isysroot $SDK_PATH" "AR=$XCODE_APP/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar" "LDFLAGS=-arch arm64 -isysroot $SDK_PATH -miphoneos-version-min=8.0"


