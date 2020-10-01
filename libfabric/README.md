## Notes on building psm and libfabric libraries used by FDS on a Linux cluster using Truelogic Infiniband cards

### Commands for building the psm library
```
cd bot/libfabric
git clone https://github.com/intel/psm.git
cd psm
module purge
make
sudo make DESTDIR=/usr/local/psm install
```

### Commands for building the libfabric library using psm built in previous step

```
cd bot/libfabric
wget https://github.com/ofiwg/libfabric/releases/download/v1.10.1/libfabric-1.10.1.tar.bz2
tar -xvf libfabric-1.10.1.tar.bz2
cd libfabric-1.10.1
 ./configure --prefix=/usr/local/libfabric --enable-psm=/usr/local/psm/usr
make
make install
```

### commands for copying the psm and libabric modules to a location where the module command can find them

```
cd bot/libfabric/modules
cp -r libfabric /usr/local/Modules/modulefiles/.
cp -r psm /usr/local/Modules/modulefiles/.

```

### Entries in the .bashrc file

module load psm
module load libfabric/1.10.1
