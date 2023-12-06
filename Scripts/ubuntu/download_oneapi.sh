#!/bin/bash
echo ""
echo "************************************"
echo "***update apt repos"
sudo apt -y update

echo downloading oneapi compilers

wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/20f4e6a1-6b0b-4752-b8c1-e5eacba10e01/l_BaseKit_p_2024.0.0.49564_offline.sh
wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/1b2baedd-a757-4a79-8abb-a5bf15adae9a/l_HPCKit_p_2024.0.0.49589_offline.sh

echo install oneapi compilers using
echo sudo sh ./l_BaseKit_p_2024.0.0.49564_offline.sh
echo sudo sh ./l_HPCKit_p_2024.0.0.49589_offline.sh



