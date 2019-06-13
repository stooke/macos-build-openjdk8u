#!/bin/bash

# from https://quuxplusone.github.io/blog/2018/04/16/building-llvm-from-source/

# define repos
LLVM_REPO_ROOT=https://github.com/llvm-mirror
LLVM_REPO_URL=$LLVM_REPO_ROOT/llvm.git
CLANG_REPO_URL=$LLVM_REPO_ROOT/clang.git

# define build environment
BUILD_DIR=`pwd`
pushd `dirname $0`
PATCH_DIR=`pwd`
popd

download_llvm_src() {
	clone_or_update $LLVM_REPO_URL              "$BUILD_DIR/llvm"
	clone_or_update $CLANG_REPO_URL             "$BUILD_DIR/llvm/tools/clang"
	clone_or_update $LLVM_REPO_ROOT/libcxx      "$BUILD_DIR/llvm/projects/libcxx"
	clone_or_update $LLVM_REPO_ROOT/compiler-rt "$BUILD_DIR/llvm/projects/compiler-rt"
	clone_or_update $LLVM_REPO_ROOT/lldb        "$BUILD_DIR/llvm/tools/lldb"
	clone_or_update $LLVM_REPO_ROOT/clang-tools-extra "$BUILD_DIR/llvm/tools/clang/tools/extra"
}

build_swig() {
	. $PATCH_DIR/tools.sh "$BUILD_DIR/tools" autoconf automake bison libtool
	clone_or_update https://github.com/swig/swig.git "$BUILD_DIR/tools/swig" 
	cd "$BUILD_DIR/tools/swig"
	# can't use pcre2 due to bug in pcre-build.sh 
	# curl -O -L https://ftp.pcre.org/pub/pcre/pcre2-10.33.tar.gz
	curl -O -L https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz
	./Tools/pcre-build.sh
	./autogen.sh && ./configure --prefix=`pwd` && make install
}

configure_llvm() {
	mkdir -p "$BUILD_DIR/llvm/build"
	cd "$BUILD_DIR/llvm/build"
	cmake -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
}

build_clang() {
	cd "$BUILD_DIR/llvm/build"
	make -j5 clang
	make -j5 check-clang
}

test_clang() {
	cd "$BUILD_DIR/llvm/build"
	./bin/llvm-lit -sv ../test/Analysis
	./bin/llvm-lit -sv ../tools/clang/test/ARCMT
	./bin/llvm-lit -sv ../projects/libcxx/test/std/re
}

. $PATCH_DIR/tools.sh "$BUILD_DIR/tools" cmake
download_llvm_src
build_swig
export PATH=$BUILD_DIR/tools/swig:$PATH
configure_llvm
time build_clang
time test_clang
