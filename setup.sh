
# Donnie V. Savage
# 10 Nov, 2021
#

if [[ "$EUID" = 0 ]]; then
    echo "Script can not be run as root"
    exit
fi

IS_SUDO=`groups | grep -c sudo`
if [ $IS_SUDO = "0" ]; then
    echo "Must be in SUDO group. As root, use command:"
    echo "    /sbin/usermod -aG sudo $USER"
    echo "    /sbin/usermod -aG adm $USER"
    echo "Then log out and back in for it to take effect"
    exit
fi

if [ ! -d ~/devel ]; then
    echo "Setup assumes development is in ~/devel"
    exit
fi

if [ ! -e etc.services ]; then
    echo "Setup must be run from the tools directory"
    exit
fi

LDFIX=`grep -c "/usr/local/lib" /etc/ld.so.conf`
if [ $LDFIX = "0" ]; then
    echo Fixing Shared library error
    sudo echo "include /usr/local/lib" | sudo tee -a /etc/ld.so.conf
    sudo ldconfig
fi

echo Install BUILD-ESSENTIAL
sudo apt install build-essential

echo Install DEVTOOLS
sudo apt-get install wget git autoconf automake libtool make \
  libreadline-dev texinfo libjson-c-dev pkg-config bison flex \
  libc-ares-dev python3-dev python3-pytest python3-sphinx build-essential \
  libsnmp-dev libcap-dev libelf-dev

sudo apt-get install libunwind-dev libprotobuf-c-dev protobuf-c-compiler

echo Install LIBYANG
if [ "`apt list -a libyang2 | grep 2.1.128`" == "" ]; then
    if [ `uname -m` == "aarch64" ]; then
	wget 'https://ci1.netdef.org/artifact/LIBYANG-LIBYANG2/shared/build-00184/Debian-12-arm8-Packages/libyang2_2.1.128.83.gfc4dbd92-1~deb12_arm64.deb'
	wget 'https://ci1.netdef.org/artifact/LIBYANG-LIBYANG2/shared/build-00184/Debian-12-arm8-Packages/libyang2-dev_2.1.128.83.gfc4dbd92-1~deb12_arm64.deb'
	wget 'https://ci1.netdef.org/artifact/LIBYANG-LIBYANG2/shared/build-00184/Debian-12-arm8-Packages/libyang2-tools_2.1.128.83.gfc4dbd92-1~deb12_arm64.deb'
	sudo apt install ./libyang2_2.1.128.83.gfc4dbd92-1~deb12_arm64.deb
	sudo apt install ./libyang2-dev_2.1.128.83.gfc4dbd92-1~deb12_arm64.deb
	sudo apt install ./libyang2-tools_2.1.128.83.gfc4dbd92-1~deb12_arm64.deb
    else
	wget 'https://ci1.netdef.org/artifact/LIBYANG-LIBYANG2/shared/build-00184/Debian-12-x86_64-Packages/libyang2_2.1.128.83.gfc4dbd92-1~deb12_amd64.deb'
	wget 'https://ci1.netdef.org/artifact/LIBYANG-LIBYANG2/shared/build-00184/Debian-12-x86_64-Packages/libyang2-dev_2.1.128.83.gfc4dbd92-1~deb12_amd64.deb'
	wget 'https://ci1.netdef.org/artifact/LIBYANG-LIBYANG2/shared/build-00184/Debian-12-x86_64-Packages/libyang2-tools_2.1.128.83.gfc4dbd92-1~deb12_amd64.deb'
	sudo apt install ./libyang2_2.1.128.83.gfc4dbd92-1~deb12_amd64.deb
	sudo apt install ./libyang2-dev_2.1.128.83.gfc4dbd92-1~deb12_amd64.deb
	sudo apt install ./libyang2-tools_2.1.128.83.gfc4dbd92-1~deb12_amd64.deb
    fi
fi

if [ "`/usr/bin/groups frr`" == "frr : frr frrvty" ] ; then
   echo Already Installed GROUPS

else
    echo Install GROUPS
    sudo addgroup --system --gid 92 frr
    sudo addgroup --system --gid 85 frrvty
    sudo adduser --system --ingroup frr --home /var/opt/frr/ --gecos "FRR suite" --shell /bin/false frr
    sudo usermod -a -G frrvty frr

    echo Add Me to FRR GROUPS
    sudo usermod -a -G frr $USER
    sudo usermod -a -G frrvty $USER
fi

echo Clone REPOS
pushd ~/devel

git clone git@github.com:diivious/eigrpd.git
git clone https://github.com/frrouting/frr.git frr
git clone https://github.com/frrouting/frr.git frr-orig

echo Config FRR
cd frr
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

echo Build FRR
make -j 8

echo Check FRR
make check

echo install FRR
sudo make install

echo Create CONFIGS
popd
sudo install -m 775 -o frr -g frrvty -d /etc/frr
sudo install -m 755 -o frr -g frrvty /dev/null /etc/frr/vtysh.conf

sudo install -m 755 -o frr -g frr -d /var/log/frr
sudo install -m 755 -o frr -g frr -d /var/opt/frr

echo Create EIGRPD CONFIG
sudo chmod 777 /etc/frr/vtysh.conf
sudo echo 'service integrated-vtysh-config' > /etc/frr/vtysh.conf
sudo cp ~/devel/frr-tools/etc.frr.frr.conf /etc/frr/frr.conf
sudo chmod 640 /etc/frr/vtysh.conf

echo Cheching /etc/services
if [ "`grep 2613 /etc/services`" = "" ]; then
    echo Patching content of etc.services to /etc/services
    sudo patch /etc/services < ~/devel/frr-tools/etc.services
fi

echo Config FRR Service
sudo cp ~/devel/frr-tools/etc.frr.daemons /etc/frr/daemons
sudo cp ~/devel/frr/tools/frr.service /etc/systemd/system/frr.service

echo daemon-reload
sudo systemctl daemon-reload
echo Start FRR Service
sudo systemctl start frr
