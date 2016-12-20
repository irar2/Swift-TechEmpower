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
  echo " or --name=<build_dir_name>"
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

# Clean if requested
if [ "$2" = "--clean" ]; then
  swift build --clean
  if [ "Linux" = $OSNAME ]; then
    rm -rf .build_gcd
  fi
fi

# Rename build dir if requested
BUILDPATH_FLAG=""
if [[ "$2" == --name=* ]]; then
  BUILD_NAME="`echo $2 | cut -d'=' -f2`"
  BUILDPATH_FLAG="--build-path=$BUILD_NAME"
fi

# Build type
case "$1" in
release)
  BUILDFLAGS="--configuration release"
  swift build $KITURA_BUILDFLAGS $BUILDFLAGS $BUILDPATH_FLAG
  if [ "Linux" = $OSNAME ]; then
    if [ ! -z "$BUILDPATH_FLAG" ]; then
      BUILD_NAME="${BUILD_NAME}_gcd"
    else
      BUILD_NAME=".build_gcd"
    fi
    BUILDPATH_FLAG="--build-path=$BUILD_NAME"
    echo "Building GCD version to $BUILD_NAME"
    KITURA_BUILDFLAGS="$KITURA_BUILDFLAGS -Xswiftc -DGCD_ASYNCH $BUILDPATH_FLAG"
    swift build $KITURA_BUILDFLAGS $BUILDFLAGS
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
  echo "Build type '$1' is not 'release' or 'debug', not building"
esac


# For 'devel', convert dependencies to full clones, so that all branches are available
case "$1" in
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
