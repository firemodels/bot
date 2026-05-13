# Install Ubuntu

follow notes here to install Ubuntu as a sub-system on a Windows 10 PC:

https://docs.microsoft.com/en-us/windows/wsl/install-win10

update packages:

sudo apt-get update

# Compiler/Module Packages

### make, gnu compilers etc
sudo apt-get install build-essential

### modules
sudo apt-get install environment-modules

# Packages for building FDS

### openmpi
sudo apt-get install openmpi-bin openmpi-common openssh-client openssh-server libopenmpi-dbg libopenmpi-dev

### gfortran
sudo apt-get install gfortran

# Packages for building/running smokeview

### opengl, glut
sudo apt-get install libglu1-mesa-dev freeglut3-dev mesa-common-dev

### x11 stuff for glut
sudo apt-get install libxmu-dev libxi-dev

### windowing stuff
sudo apt-get install xinit

### add following to .bashrc 

export DISPLAY=:0

To run smokeview, you need to also run Xming on your PC.


