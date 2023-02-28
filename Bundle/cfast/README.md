#  cfast bundle scripts

This directory contains scripts for building cfast bundles.

### Setting up repos for building a cfast bundle
1. Create a directory named FireModels_cbundle in your home directory to contain the bot, cfast and smv repos by opening a command shell and typing: 

```
mkdir %userprofile%\FireModels_cbundle
```

2. cd into FireModels_cbundle and clone the bot repo by typing: 

```
git clone https://github.com/firemodels/bot.git 
```
or 
```
git clone https://github.com/username/bot.git 
```
if you forked the bot repo where username is your github username. I

3. cd into `FireModels_cbundle\bot\Bundle\cfast`

4. copy bundle_config.bat to %userprofile%\.bundle\bundle_config.bat .  Edit the settings in bundle_config.bat to match your computing environment.

### Building a bundle
1. Get the CFAST manuals by typing `copy_pubs_fromrepo -r repo_root` or `copy_pubs_fromhost` depending on whether you ran cfastbot 
on your PC or a linux cluster. Both scripts put the manuals (pdf files) in the directory `%userprofile%\.cfast\PDFS`
which is where the cfast bundle scripts get them.

3. Finally, to build a bundle, type: `build_bundle`

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
