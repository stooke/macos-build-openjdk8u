#!/bin/bash
#set -x
NUM=00
PATCH_DIR=`pwd`/xx
WEBREV_BASE=`pwd`/webrevs
. $PATCH_DIR/tools.sh `pwd`/tools webrev mercurial
mkdir -p "$WEBREV_BASE"
cd jdk8u*
repos="jdk hotspot corba nashorn langtools jaxp jaxws"

mkwebrev() {
  REPO_DIR=$1
  WEBREV_DIR=$2
  pushd "$REPO_DIR" >/dev/null
  N=`hg status | wc -l`
  if [ $N != 0 ] ; then
    webrev.ksh
    mv webrev "$WEBREV_DIR"
  else
    echo "  (no differences)"
  fi
  popd >/dev/null
}

mkwebrev . $WEBREV_BASE/webrev.$NUM

for a in $repos ; do 
  echo processing `pwd`/$a
  mkwebrev $a $WEBREV_BASE/webrev.$a.$NUM
done

