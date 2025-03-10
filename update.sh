#!/usr/bin/bash
#
# Donnie V. Savage
# 10 Nov, 2021
#
if [ ! -d ~/devel ]; then
    echo "Setup assumes development is in ~/devel"
    exit
fi

cd ~/devel
if [ -d "$1" ]; then
    target=$1
    shift;
else
    target="eigrpd"
fi

# If ever this grows, then do better commandline arg processing
if [ "x$1" = "x-all" ]; then
    echo Updating FRR-ORIG
    cd ~/devel/frr-orig
    git fetch
    git pull
fi

echo Updating $target
cd ~/devel/$target
    git fetch
    git pull

echo Updating FRR
cd ~/devel/frr
    rm -rf eigrpd
    git fetch
    git pull

echo Copying $target
cd ~/devel/frr
    rm -rf eigrpd
    ln -s ../$target eigrpd

