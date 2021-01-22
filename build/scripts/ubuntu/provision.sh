#!/bin/bash -e
git clone https://github.com/incredincomp/the_hunting.git
cd ./the_hunting
git clone https://github.com/projectdiscovery/nuclei-templates.git
./files/conf/install.sh --install
curl https://sh.rustup.rs -sSf | sh
