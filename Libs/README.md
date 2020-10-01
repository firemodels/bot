
1. build psm library

git clone https://github.com/intel/psm.git
cd psm
module purge
make
sudo make DESTDIR=/usr/local/psm install

2. build libfabric library

wget https://github.com/ofiwg/libfabric/releases/download/v1.10.1/libfabric-1.10.1.tar.bz2
tar -xvf libfabric-1.10.1.tar.bz2
cd libfabric-1.10.1
 ./configure --prefix=/usr/local/libfabric --enable-psm=/usr/local/psm/usr
make
make install
