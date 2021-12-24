#!/bin/bash

for i in $*;
do
    params="$params $i"
done

winpty bash -c "MSYS_NO_PATHCONV=1 docker run --rm -it -v $(pwd):/src -p 1313:1313 klakegg/hugo:0.91.2 $params"