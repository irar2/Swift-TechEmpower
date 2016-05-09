#!/bin/sh

# First time setup:
# Mac:
# brew install http-parser pcre2 curl hiredis
# Linux:
# sudo apt-get install libhttp-parser-dev libcurl4-openssl-dev libhiredis-dev

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
  #KITURA_BUILDFLAGS="-Xcc -fblocks -Xlinker -rpath -Xlinker .build/$1"
  KITURA_BUILDFLAGS="-Xcc -fblocks -Xlinker -rpath=\$ORIGIN"
  ;;
Darwin)
  KITURA_BUILDFLAGS="-Xcc -fblocks -Xswiftc -I/usr/local/include -Xlinker -L/usr/local/lib"
  ;;
*)
  echo "Unknown OS `uname`"
  exit 1
esac

swift build --clean
swift build $KITURA_BUILDFLAGS $BUILDFLAGS
