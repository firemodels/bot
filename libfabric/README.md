## Using psm and libfabric libraries

Add the following entries to your .bashrc file.  Only do this if psm and libfabric were built using notes in the next section.

```
module load psm
module load libfabric/1.10.1
```

## Building psm and libfabric libraries

These notes are for building psm and libfabric libraries on a Linux cluster which uses Truelogic Infiniband cards

1. Build the psm library
```
cd bot/Libs
git clone https://github.com/intel/psm.git
cd psm
module purge
make
sudo make DESTDIR=/usr/local/psm install
```

2. Build the libfabric library using psm built in previous step

```
cd bot/Libs
wget https://github.com/ofiwg/libfabric/releases/download/v1.10.1/libfabric-1.10.1.tar.bz2
tar -xvf libfabric-1.10.1.tar.bz2
cd libfabric-1.10.1
 ./configure --prefix=/usr/local/libfabric --enable-psm=/usr/local/psm/usr
make
make install
```

3. Copy the psm and libabric modules to a location where the module command can find them

```
cd bot/Libs/modules
cp -r libfabric /usr/local/Modules/modulefiles/.
cp -r psm /usr/local/Modules/modulefiles/.

```

