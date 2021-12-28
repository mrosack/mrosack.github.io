#!/bin/bash

HUGO_VERSION=0.91.2
platform="unix"

if [ "$OSTYPE" = "msys" ] || [ "$OSTYPE" = "cygwin" ]; then
  platform="windows"
fi

for i in $*;
do
    if [ $platform == "windows" ] && [ "$i" == "server" ]; then
        params="$params server --poll 1s"
    else
        params="$params $i"
    fi
done

if [ $platform = "windows" ]; then
    winpty bash -c "MSYS_NO_PATHCONV=1 docker run --rm -it -v $(pwd):/src -p 1313:1313 klakegg/hugo:$HUGO_VERSION $params"
else
    docker run --rm -it -v $(pwd):/src -p 1313:1313 klakegg/hugo:$HUGO_VERSION $params
fi