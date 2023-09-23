#!/bin/bash
sudo apt -y update

# install packages for building fds
sudo apt -y install gfortran openmpi-bin openmpi-doc libopenmpi-dev 

# install packages for building smokeview
sudo apt -y install freeglut3-dev mesa-utils libx11-dev libxmu-dev libxi-dev
sudo apt -y install clang-format clang-tidy

# install packages for building manuals
sudo apt -y install texlive texlive-latex-recommended texlive-latex-extra texlive-science

# install package for comparing images
sudo apt -y install imagemagick-6.q16

echo "see following url for installing latest gh (command line version of git)
echo https://github.com/cli/cli/blob/trunk/docs/install_linux.md 



