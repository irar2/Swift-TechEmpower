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
  echo "Optionally add --clean"
  exit 1
fi

# Build flags for Kitura appropriate for current OS
case `uname` in
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
  echo "Unknown OS `uname`"
  exit 1
esac

# Clean if requested
if [ "$2" = "--clean" ]; then
  swift build --clean
fi

# Build type
case "$1" in
release)
  BUILDFLAGS="--configuration release"
  swift build $KITURA_BUILDFLAGS $BUILDFLAGS
  ;;
debug)
  BUILDFLAGS=""
  swift build $KITURA_BUILDFLAGS $BUILDFLAGS
  ;;
fetch|devel)
  swift package fetch
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
  ;;
esac
