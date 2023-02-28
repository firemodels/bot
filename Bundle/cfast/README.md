#  cfast bundle scripts

This directory contains scripts for building cfast bundles.

### Setting up repos for building a cfast bundle
1. Go to the github website and fork the bot repo
2. Create a directory named FireModels_cbundle in your home directory by opening a command shell and typing: 
`mkdir %userprofile%\FireModels_cbundle`
4. cd into FireModels_cbundle and clone the bot repo by typing: git clone https://github.com/username/bot.git where username is your github username.
5. cd into FireModels_cbundle/bot/Bundle/cfast
6. copy bundle_config.bat to %userprofile%\.bundle\bundle_config.bat .  Edit the settings in bundle_config.bat to match your computing environment.

### Building a bundle
1. Get the CFAST manuals from a local cfastbot run or from a cfastbot runby typing type: copy_pubs_fromrepo if you ran cfast bot on your PC or copy_pubs_fromhost if you ran cfastbot on your Linux cluster.
2. to build a bundle, type: build_bundle

### build_bundle usage
```
build_bundle [options]

Options:
-B      - use cfast and smv commits from the latest cfastbot pass
-C hash - build bundle using cfast repo commit with hash 'hash' .
          If hash=latest then use most the recent commit (default: latest)
-E        skip Cedit build
-f      - force erasing and cloning of cfast and smv repos without warning first
-h      - display this message
-I      - assume apps are built, only build installer
-S hash - build bundle using smv repo commit with hash 'hash' .
          If hash=latest then use most the recent commit (default: latest)
-u      - upload bundle to a google drive directory
```
