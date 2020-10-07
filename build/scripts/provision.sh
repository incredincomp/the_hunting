#!/bin/bash -e
git clone --recurse-submodules https://github.com/incredincomp/the_hunting.git
cd ./the_hunting
git pull --recurse-submodules
git submodule update --remote --recursive
./install.sh --install
