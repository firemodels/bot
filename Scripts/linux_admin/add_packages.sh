#!/bin/bash
server=1

# change above line to
# server=
# if setting up a a compute node

# ----------------------------------------------
#   preliminaries 

#   *** add user and setup to use sudo

#   run the adduser command and edit the /etc/sudoers
#   file to setup a user

#   adduser username  
#   vi /etc/sudoers

#   then copy entry for root changing root to username

# *** change dns server in /etc/resolv.conf

#   nameserver 208.67.222.222

# *** after this script runs, run the following command
#     to add a user to samba (username is name you use to login )

#   sudo smbpasswd -a username
# ----------------------------------------------

# *** update raspberry OS

 sudo apt-get -y update
 sudo apt-get -y dist-upgrade

# ***  install gfortran

 sudo apt-get -y install gfortran

# *** install Xvfb (for use by smokebot)

  sudo apt-get -y install xvfb

# *** install  mpich

# note: mpich uses mpif90 (not mpifort) when building fds

  sudo apt-get -y install libcr-dev mpich mpich-doc

# *** install samba
  if [ "$server" != "" ]; then
    sudo apt-get -y install samba
  fi

#  to add a user:

# sudo smbpasswd -a username

# *** install OpenGL libraries and headers
  
  if [ "$server" != "" ]; then
    sudo apt-get -y install libgl1-mesa-dri
    sudo apt-get -y install mesa-common-dev
    sudo apt-get -y install freeglut3-dev
    sudo apt-get -y install libxmu-dev libxi-dev
  fi

# *** install mail
  
  if [ "$server" != "" ]; then
    sudo apt-get -y install postfix
    sudo apt-get -y  install mailutils
  fi

# *** install bc

  sudo apt-get -y install bc

# *** install torque

# https://jabriffa.wordpress.com/2015/02/11/installing-torquepbs-job-scheduler-on-ubuntu-14-04-lts/

  if [ "$server" != "" ]; then
    # head nodes
    sudo apt-get -y install torque-server torque-scheduler torque-mom torque-client
  else
    # compute nodes
    sudo apt-get -y install torque-client torque-mom
  fi

#  note: before configuring torque, edit /etc/hosts file to add entry for all hosts

# *** install tex

  if [ "$server" != "" ]; then
    sudo apt-get -y install texlive
  fi
