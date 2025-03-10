#!/usr/bin/bash
#
# Donnie V. Savage
# 10 Nov, 2021
#

if [ ! -d ~/devel ]; then
    echo "Setup assumes development is in ~/devel"
    exit
fi

# If ever this grows, then do better commandline arg processing
cd ~/devel/frr

if [ "x$1" = "x-config" ]; then
    shift
   ./bootstrap.sh
   ./configure \
       --sysconfdir=/etc \
       --localstatedir=/var \
       --sbindir=/usr/lib/frr \
       --enable-multipath=64 \
       --enable-user=frr \
       --enable-group=frr \
       --enable-vty-group=frrvty \
       --enable-configfile-mask=0640 \
       --enable-logfile-mask=0640 \
       --enable-fpm \
       --with-pkg-git-version \
       --with-pkg-extra-version=
else
    make -j 8
fi
