#!/bin/bash

for i in $*;
do
    if [ "$i" == "server" ]; then
        params="$params server --poll 1s"
    else
        params="$params $i"
    fi
done

winpty bash -c "MSYS_NO_PATHCONV=1 docker run --rm -it -v $(pwd):/src -p 1313:1313 klakegg/hugo:0.91.2 $params"