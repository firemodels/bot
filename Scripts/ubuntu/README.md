# Setting up Ubuntu

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
