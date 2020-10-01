
1. build psm library

### Commands for building psm library
```
cd bot/libfabric
git clone https://github.com/intel/psm.git
cd psm
module purge
make
sudo make DESTDIR=/usr/local/psm install
```

### commands commands for building libfabric library using psm built in first step

cd bot/libfabric
wget https://github.com/ofiwg/libfabric/releases/download/v1.10.1/libfabric-1.10.1.tar.bz2
tar -xvf libfabric-1.10.1.tar.bz2
cd libfabric-1.10.1
 ./configure --prefix=/usr/local/libfabric --enable-psm=/usr/local/psm/usr
make
make install

### commands for copying modules to where module command can find them
cd bot/libfabric/modules
cp -r libfabric /usr/local/Modules/modulefiles/.
cp -r psm /usr/local/Modules/modulefiles/.
