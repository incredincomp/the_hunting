#!/bin/bash

# all failures are hard-failures
set -e

# turn on verbose output if $DEBUG is set
if [ -n $DEBUG ]; then
    set -x
fi

# explicitly set $GOPATH to default
export GOPATH="${HOME}/go"

# explicitly modify path for this run
export PATH="${PATH}:${GOPATH}/bin:${HOME}/.local/bin"

export THE_HUNTING_REPO="https://github.com/incredincomp/the_hunting"
export THE_HUNTING_BRANCH="main"

declare -a DNF_PACKAGES=(
    "chromium"
    "git"
    "golang"          # required for building GO based tools
    "java-11-openjdk" # required for ZAP
    "jq"
    "make"
    "parallel"
    "podman-docker" # docker CLI alias for podman
    "p7zip*"        # required for some native bin installs
    "python"
    "python-pip"
    "s3fs-fuse"
    "tmux"
    "unzip"
    "wget"
)

declare -a NATIVE_BINS=(
    "amass"
    "aquatone"
    "gobuster"
    "httprobe"
    "nuclei"
    "subfinder"
)

declare -a GO_MODULES=(
    "github.com/haccer/subjack"
)

declare -a PYTHON_PACKAGES=(
    "awscli"
)

function bootstrap() {
    # update all packages
    dnf update -y
}

function install_dnf_packages() {
    dnf install -y ${DNF_PACKAGES[@]}
}

# use https://github.com/1efty/pkgs to install native binaries for
# various compiled tools
# this handles the logic required to install these tools
function install_native_bins() {
    git clone https://github.com/1efty/pkgs
    pushd pkgs
    for pkg in ${NATIVE_BINS[@]}; do
        make -C install $pkg
    done
    popd
    rm -rf pkgs
}

function install_go_mods() {
    for mod in ${GO_MODULES[@]}; do
        go get $mod
    done
}

# install Python packages to system site-packages
# bins should be installed in /usr/local/bin
function install_python_packages() {
    for pkg in ${PYTHON_PACKAGES[@]}; do
        python3 -m pip install $pkg
    done
}

function setup_environment() {
    # update environment for all users
    cat >/etc/profile.d/env.sh <<-EOF
export GOPATH="${HOME}/go"
export PATH="${PATH}:${GOPATH}/bin:${HOME}/.local/bin"
EOF
}

function install_zap() {
    curl -sSL https://github.com/zaproxy/zaproxy/releases/download/v2.9.0/ZAP_2.9.0_Crossplatform.zip -o zap.zip
    unzip zap.zip && mv ZAP_2.9.0 zap
    rm -rf zap.zip
}

function install_the_hunting() {
    git clone --recursive -b $THE_HUNTING_BRANCH $THE_HUNTING_REPO
}

function cleanup() {
    dnf clean all -y
}

function main() {
    bootstrap
    install_dnf_packages
    install_native_bins
    install_go_mods
    install_python_packages
    install_zap
    setup_environment
    install_the_hunting
    cleanup
}

main
