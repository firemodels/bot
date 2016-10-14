#!/bin/bash

# 0. add user

#   adduser username  

# 1. add username to sudo list

#  sudo visudo

# then copy entry for root changing root to username

# 2.  change dns server in /etc/resolv.conf

# I changed dns server entry to the following number (google for opendns)

# nameserver 208.67.222.222

# do the following before updating libraries

 sudo apt-get update
 sudo apt-get dist-upgrade

# 3.  install gfortran

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

# 8 OpenGL libraries and headers
#  think the following two are already installed
  sudo apt-get install libgl1-mesa-dri
  sudo apt-get install mesa-common-dev

# freeglut provides the OpenGL headers
  sudo apt-get install freeglut3-dev
  sudo apt-get install libxmu-dev libxi-dev

# 9.  mail

  sudo apt-get install postfix

# 10.0 bc

  sudo apt-get install bc

# 11: torque

# I used notes from this page to install and configure torque
# https://jabriffa.wordpress.com/2015/02/11/installing-torquepbs-job-scheduler-on-ubuntu-14-04-lts/

# server (for the first pi)
  sudo apt-get install torque-server torque-scheduler torque-mom torque-client

# client ( for the 2nd throught the nth pi)
  sudo apt-get install torque-client torque-mom

# 12: tex

  sudo apt-get install texlive-full
