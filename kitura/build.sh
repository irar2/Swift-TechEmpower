#!/bin/sh

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

# Build type
case "$1" in
release)
  BUILDFLAGS="--configuration release"
  swift build $KITURA_BUILDFLAGS $BUILDFLAGS
  if [ "Linux" = $OSNAME ]; then
    echo "Building GCD version to .build_gcd"
    KITURA_BUILDFLAGS="$KITURA_BUILDFLAGS -Xswiftc -DGCD_ASYNCH --build-path .build_gcd"
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
