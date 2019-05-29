# Installing Ubuntu as a sub-system on a Windows 10 PC

### follow notes here:
https://docs.microsoft.com/en-us/windows/wsl/install-win10


## After Linux is installed, install/update the following packages

### update packages
sudo apt-get update

### make, gnu compilers etc
sudo apt-get install build-essential

### openmpi
sudo apt-get install openmpi-bin openmpi-common openssh-client openssh-server libopenmpi-dbg libopenmpi-dev

### gfortran
sudo apt-get install gfortran

### opengl, glut
sudo apt-get install libglu1-mesa-dev freeglut3-dev mesa-common-dev

### x11 stuff for glut
sudo apt-get install libxmu-dev libxi-dev

### windowing stuff (run startx to be able to run smokeview)
sudo apt-get install xinit

### add following to .bashrc 

export DISPLAY=:0

On your Windows 10 PC you need to run Xming.

