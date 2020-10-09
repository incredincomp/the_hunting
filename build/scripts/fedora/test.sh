#!/bin/bash -l
# use -l to invoke BASH as a login shell, or else /etc/profile.d/*.sh are not sourced at runtime

set -e

which aws
which chromium-browser
which docker
which git
which go
which jq
which make
which parallel
which python3
which subjack
which s3fs
which unzip
which wget

test -f ~/zap/zap.sh

which amass
which aquatone
which gobuster
which httprobe
which nuclei
which subfinder
which subjack
