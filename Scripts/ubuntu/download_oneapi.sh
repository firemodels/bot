#!/bin/bash
echo ""
echo "************************************"
echo "***update apt repos"
sudo apt -y update

echo downloading oneapi compilers
wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/992857b9-624c-45de-9701-f6445d845359/l_BaseKit_p_2023.2.0.49397_offline.sh
wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/0722521a-34b5-4c41-af3f-d5d14e88248d/l_HPCKit_p_2023.2.0.49440_offline.sh

echo install oneapi compilers using
echo sudo sh ./l_BaseKit_p_2023.2.0.49397_offline.sh
echo sudo sh ./l_HPCKit_p_2023.2.0.49440_offline.sh



