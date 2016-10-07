#!/bin/bash

# 0. add user

#   adduser username  

# 1. add username to sudo list

#  sudo visudo

# then copy entry for root changing root to username

# 2.  change dns server in /etc/resolv.conf

# I changed dns server entry to the following number (google for opendns)

# nameserver 208.67.222.222

# 3.  install gfortran

 sudo apt-get update
 sudo apt-get install gfortran

# 4. install Xvfb (for use by smokebot)

# sudo apt-get install xvfb

# 5.  install OpenMPI

# sudo apt-get install openmpi-bin
# note: this does not install mpifort (so don't install this package)

# 6. install  mpich

# note: the following installs mpif90 
# to build an mpi fortran edit the mpi_gnu_linux_64 entry by removing -m64 and
# changing mpifort to mpif90

  sudo apt-get install libcr-dev mpich2 mpich2-doc


# 7 add samba

  sudo apt-get install samba

#  to add a user:

  sudo smbpasswd -a username


