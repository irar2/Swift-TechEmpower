#!/bin/bash
#
# Copyright IBM Corporation 2016
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# First time setup:
# Mac:
# brew install curl
# Linux:
# sudo apt-get install autoconf libtool libkqueue-dev libkqueue0 libcurl4-openssl-dev libbsd-dev libblocksruntime-dev

if [ -z "$1" ]; then
  echo "Specify build type (release or debug),"
  echo " or fetch (to just fetch dependencies),"
  echo " or devel (fetch dependencies and convert to full clones)"
  echo "  - for devel, optional 2nd argument is branch name to switch dependencies to"
  echo " or status (to show status of packages and builds)"
  echo "Optionally add --clean"
  echo " or --name=<build_dir_name> or --build-path=<build_dir_name>"
  exit 1
fi

OSNAME=`uname`

# Build flags for Kitura appropriate for current OS
case $OSNAME in
Linux)
  # Add include for postgres
  KITURA_BUILDFLAGS="-Xcc -fblocks -Xcc -I/usr/include/postgresql"
  # Uncomment to switch to the cross-platform (DispatchSource) keepalive implementation
  # KITURA_BUILDFLAGS="$KITURA_BUILDFLAGS -Xswiftc -DGCD_ASYNCH"
  ;;
Darwin)
  # Add include and libpath for postgres
  KITURA_BUILDFLAGS="-Xcc -I/usr/local/include -Xlinker -L/usr/local/lib/"
  ;;
*)
  echo "Unknown OS $OSNAME"
  exit 1
esac

BUILD_NAME=".build"
BUILDPATH_FLAG=""
COMMAND="status"

# Consume optional flags
for ARG in $*; do
  LHS=`echo $ARG | cut -d'=' -f1`
  echo $LHS
  case $LHS in
  "--clean"):
    CLEAN=1
    ;;
  "--name"|"--build-path"):
    BUILD_NAME="`echo $ARG | cut -d'=' -f2`"
    BUILDPATH_FLAG="--build-path=$BUILD_NAME"
    ;;
  "release"|"debug"|"fetch"|"devel"|"status"):
    COMMAND=$LHS
    ;;
  *)
    echo "Unrecognized arg: $ARG"
  esac
done
    
# Clean if requested
if [ $CLEAN ]; then
  swift build $BUILDPATH_FLAG --clean
  if [ "Linux" = $OSNAME ]; then
    swift build ${BUILDPATH_FLAG}_gcd --clean
  fi
fi

# Build type
case "$COMMAND" in
release)
  BUILDFLAGS="--configuration release"
  GCD_BUILDFLAGS="-Xswiftc -DGCD_ASYNCH"
  TCM_BUILDFLAGS="-Xlinker -L/usr/local/lib/ -Xlinker -ltcmalloc"
  TCMM_BUILDFLAGS="-Xlinker -L/usr/lib/ -Xlinker -ltcmalloc_minimal"
  swift build $KITURA_BUILDFLAGS $BUILDFLAGS $BUILDPATH_FLAG
  if [ "Linux" = $OSNAME ]; then
    if [ ! -z "$BUILDPATH_FLAG" ]; then
      BUILD_NAME="${BUILD_NAME}"
    else
      BUILD_NAME=".build"
    fi
    echo "Building GCD version to ${BUILD_NAME}_gcd"
    BUILDPATH_FLAG="--build-path=${BUILD_NAME}_gcd"
    swift build $KITURA_BUILDFLAGS $GCD_BUILDFLAGS $BUILDFLAGS $BUILDPATH_FLAG
    if [ -f /usr/local/lib/libtcmalloc.so ]; then
        echo "Building tcmalloc version to ${BUILD_NAME}_tcmalloc"
        BUILDPATH_FLAG="--build-path=${BUILD_NAME}_tcmalloc"
        swift build $KITURA_BUILDFLAGS $TCM_BUILDFLAGS $BUILDFLAGS $BUILDPATH_FLAG
        echo "Building GCD + tcmalloc version to ${BUILD_NAME}_gcd_tcmalloc"
        BUILDPATH_FLAG="--build-path=${BUILD_NAME}_gcd_tcmalloc"
        swift build $KITURA_BUILDFLAGS $TCM_BUILDFLAGS $GCD_BUILDFLAGS $BUILDFLAGS $BUILDPATH_FLAG
    fi
    if [ -f /usr/lib/libtcmalloc_minimal.so ]; then
        echo "Building tcmalloc_minimal version to ${BUILD_NAME}_tcmalloc_min"
        BUILDPATH_FLAG="--build-path=${BUILD_NAME}_tcmalloc_min"
        swift build $KITURA_BUILDFLAGS $TCMM_BUILDFLAGS $BUILDFLAGS $BUILDPATH_FLAG
        echo "Building GCD + tcmalloc_minimal version to ${BUILD_NAME}_gcd_tcmalloc_min"
        BUILDPATH_FLAG="--build-path=${BUILD_NAME}_gcd_tcmalloc_min"
        swift build $KITURA_BUILDFLAGS $TCMM_BUILDFLAGS $GCD_BUILDFLAGS $BUILDFLAGS $BUILDPATH_FLAG
    fi
  fi
  ;;
debug)
  BUILDFLAGS=""
  swift build $KITURA_BUILDFLAGS $BUILDFLAGS
  ;;
fetch|devel)
  swift package fetch
  ;;
status)
  # Status about each build directory. Assuming for the moment that the first executable
  # found in each directory is representative (in terms of build date and Swift version)
  echo "Builds:"
  BUILD_DIRS=`find .build*/release .build*/debug build*/release build*/debug -prune -print 2>/dev/null`
  for buildDir in $BUILD_DIRS; do
    SOME_EXE=`find $buildDir/* -type f -print -o -prune 2>/dev/null | grep -v '\.\(swift\|dylib\|so\)' | head -n1`
    case $OSNAME in
      Linux)
        SWIFTPATH=`ldd $SOME_EXE | grep 'usr/lib/swift/linux' | head -n1 | sed -e's#/usr/lib/swift.*##' -e's#.*=> ##'`
        MODTIME=`stat -c '%Y' $SOME_EXE`
        MODDATE=`date -d "@$MODTIME"`
        ;;
      Darwin)
        SWIFTPATH=`otool -l $SOME_EXE | grep 'lib/swift' | head -n1 | sed -e's#/usr/lib/swift.*##' -e's# *path ##'`
        MODDATE=`stat -f '%Sm' $SOME_EXE`
        ;;
    esac
    echo "$buildDir: built on $MODDATE"
    echo " - built with $SWIFTPATH"
  done
  ;;
*)
  echo "'$COMMAND' not recognized"
esac


# For 'devel', convert dependencies to full clones, so that all branches are available
case "$COMMAND" in
devel)
  WORKDIR=$PWD
  for dir in `find Packages/* -type d -prune -print`; do
    echo "Converting $dir to full clone"
    cd $dir && git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*" && git fetch origin
    if [ ! -z "$2" ]; then
      git checkout origin/$2 && git pull origin $2 && echo "Switched $dir to branch $2"
    fi
    cd $WORKDIR
  done
  # Rebuild xcode project after updating dependencies
  swift package generate-xcodeproj
  ;;
status)
  echo "Packages:"
  cd Packages
  WORKDIR=$PWD
  for dir in `find * -type d -prune -print`; do
    cd $dir
    BRANCH=`git status | head -n1`
    echo "$dir: $BRANCH"
    cd $WORKDIR
  done
  ;;
esac
