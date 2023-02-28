#  cfast bundle scripts

This directory contains scripts for building cfast bundles.

## Setting a repos for building a cfast bundle
1. Go to the github website and fork the bot repo
2. Create a directy named FireModels_cbundle in your home directory ( %userprofile% )
3. cd into FireModels_cbundle and clone the bot repo by typing: git clone https://github.com/username/bot.git where user name is your github username.
4. cd into FIreModels_cbundle/bot/Bundle/cfast
5. copy bundle_config.bat to %userprofile%\.bundle\bundle_config.bat .  Edit settings in bundle_config.bat to match your computing environment.
6. Get the manuals by typing type: copy_pubs_fromrepo if you ran cfast bot on your PC or copy_pubs_fromhost if you ran cfastbot on your Linux cluster.
7. to build a bundle, type: build_bundle
