#!/bin/bash
echo ""
echo "************************************"
echo "***update apt repos"
sudo apt -y update

echo downloading oneapi compilers

wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/6caa93ca-e10a-4cc5-b210-68f385feea9e/intel-oneapi-base-toolkit-2025.3.1.36_offline.sh
wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/f59a79aa-4a6e-46e8-a6c2-be04bb13f274/intel-oneapi-hpc-toolkit-2025.3.1.55_offline.sh

#echo install oneapi compilers using
#sudo sh ./intel-oneapi-base-toolkit-2025.3.1.36_offline.sh -a --silent --cli --eula accept -a --silent --cli --eula accept
#sudo sh ./intel-oneapi-hpc-toolkit-2025.3.1.55_offline.sh -a --silent --cli --eula accept -a --silent --cli --eula accept

#echo add essential packages
#sudo apt update
#sudo apt -y install cmake pkg-config build-essential
