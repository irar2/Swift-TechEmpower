#!/bin/sh

# First time setup:
# Mac:
# brew install curl
# Linux:
# sudo apt-get install autoconf libtool libkqueue-dev libkqueue0 libcurl4-openssl-dev libbsd-dev libblocksruntime-dev

if [ -z "$1" ]; then
  echo "Specify build type (release or debug)"
  exit 1
fi

# Build type
case "$1" in
release)
  BUILDFLAGS="--configuration release"
  ;;
debug)
  BUILDFLAGS=""
  ;;
*)
  echo "Build type '$1' is not 'release' or 'debug' - building debug"
  BUILDFLAGS=""
esac

# Build flags for Kitura appropriate for current OS
case `uname` in
Linux)
  #KITURA_BUILDFLAGS="-Xcc -fblocks -Xlinker -rpath=\$ORIGIN"
  KITURA_BUILDFLAGS="-Xcc -fblocks"
  ;;
Darwin)
  #KITURA_BUILDFLAGS="-Xcc -fblocks -Xswiftc -I/usr/local/include -Xlinker -L/usr/local/lib"
  KITURA_BUILDFLAGS=""
  ;;
*)
  echo "Unknown OS `uname`"
  exit 1
esac

swift build --clean
swift build $KITURA_BUILDFLAGS $BUILDFLAGS
