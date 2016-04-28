#!/bin/sh

# First time setup:
# Mac:
# brew install http-parser pcre2 curl hiredis
# Linux:
# sudo apt-get install libhttp-parser-dev libcurl4-openssl-dev libhiredis-dev

swift build --clean

case `uname` in
Linux)
  swift build -Xcc -fblocks -c release
  ;;
Darwin)
  swift build -Xcc -fblocks -Xswiftc -I/usr/local/include -Xlinker -L/usr/local/lib -c release
  ;;
*)
  echo "Unknown OS `uname`"
esac

