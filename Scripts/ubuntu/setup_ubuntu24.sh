#!/bin/bash
echo ""
echo "************************************"
echo "***update apt repos"
sudo apt -y update

echo ""
echo "************************************"
echo ***install packages for building fds
#sudo apt -y install gfortran openmpi-bin openmpi-doc libopenmpi-dev 
sudo apt -y install gfortran

echo ""
echo "************************************"
echo ***install packages for building smokeview
sudo apt -y install libx11-dev libxmu-dev libxi-dev
sudo apt -y install mesa-common-dev mesa-utils libgl-dev libglu1-mesa-dev
sudo apt -y install ffmpeg
sudo apt -y install clang-format clang-tidy

echo ""
echo "************************************"
echo ***install packages for building manuals
sudo apt -y install texlive texlive-latex-recommended texlive-latex-extra texlive-science

echo ""
echo "************************************"
echo ***install package for comparing images
sudo apt -y install imagemagick-6.q16

echo ""
echo "************************************"
echo "***install gh using commands from:"
echo "https://github.com/cli/cli/blob/trunk/docs/install_linux.md "

#type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
#curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
#&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
#&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
#&& sudo apt update \
#&& sudo apt install gh -y

# download and setup oneapi compilers

echo use download_oneapi.sh script to download oneapi compilers 
