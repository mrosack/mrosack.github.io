+++
title = "Developing a Hugo Site on Windows with Docker"
date = "2021-12-25T12:07:32Z"
author = "Mike Rosack"
authorTwitter = "mike_rosack" #do not include @
cover = ""
tags = ["docker", "hugo", "windows", "bash"]
keywords = ["docker", "hugo", "windows", "bash"]
readingTime = true
+++

I've been wanting to retire the Wordpress site I threw up 4 years ago when I went independent pretty much from the moment I published it.  About a year and a half ago I finally got serious and started working on a replacement using [Eleventy](https://www.11ty.dev/), but I'm just not enough of a CSS guru to make something look great from scratch.  This Christmas break I decided to give it another go and took a look at [Hugo](https://gohugo.io/), which I had originally dismissed because I wanted something javascripty, but then I started using it and got from 0 to a pretty nice site in just a day or two.

That said, there were a couple hangups I had to get over, mostly because I'm a stubborn Windows user from my days working with .NET.  I didn't want to install the Hugo binary locally, and there's a nice [Hugo docker image](https://hub.docker.com/r/klakegg/hugo/), so I wanted to set up a dev env to run Hugo from docker.  That seems easy, but it never is on Windows.  Here's the final script I ended up with, but we'll talk through some issues I had:

{{< code language="bash" >}}
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
{{</code>}}

* **Path Conversion:** Windows bash tries to be helpful and convert paths for you, but this can screw up the docker -v parameter to mount volumes.  Adding ```MSYS_NO_PATHCONV=1``` as an environment variable takes care of that issue.

* **General winpty issues:** If you've done much with Docker and Windows, you're probably familiar with this: ```the input device is not a TTY.  If you are using mintty, try prefixing the command with 'winpty'```.  But it's never as easy as just adding winpty at the front - just following that suggestion caused the parameters not to be passed in correctly.  I ended up using winpty to call a bash subprocess, passing in the entire command to run.

* **File watching broken:** On the computer I was developing on I had WSL 1, not 2, but I think this issue would be present on WSL 2 if you're developing on the Windows file system and not the Linux image - because the data is shared over a file share checking for file updates doesn't work.  Hugo has a workaround for this with the ```--poll``` option, so I added a special case to check if we're running the server and add the poll command automatically on windows.

After all this, I could run the standard Hugo command line stuff like ```./hugo-docker.sh server``` and ```./hugo-docker.sh new posts/hugo-windows-docker.md```, and I could also include the script in my github actions workflow to build and deploy the site.  Check out the full repo here if you're interested: https://github.com/mrosack/mrosack.github.io