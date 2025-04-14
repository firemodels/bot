#  cfast bundle scripts

This directory contains scripts for building cfast bundles.

### Setting up repos for building a cfast bundle
1. Create a directory named FireModels_cbundle in your home directory that will contain the bot, cfast and smv repos.
Open a command shell and type: `mkdir %userprofile%\FireModels_cbundle` .  Note this directory name is arbitrary.

2. cd into FireModels_cbundle and clone the bot repo by typing: `git clone https://github.com/firemodels/bot.git` .
If your forked the bot repo you could type `git clone https://github.com/username/bot.git` instead
where username is your github username.

### Building a bundle
1. cd into `FireModels_cbundle\bot\Bundlebot\cfast`

2. Get the CFAST manuals by typing `copy_pubs_fromrepo -r repo_root` or `copy_pubs_fromhost` 
depending on whether you ran cfastbot on your PC or a linux cluster. 
If you ran cfastbot on your PC, `repo_root` is the directory containing the `cfast` repo where you
ran cfastbot.  Both scripts put the manuals (pdf files) into the directory `%userprofile%\.cfast\PDFS`
which is where the cfast bundle scripts obtain them.

3. Finally, to build a bundle, type: `run_cfastbundle`

### run_cfastbundle usage
There are several options for building a bundle. To build a bundle without CEdit (perhaps you don't have
license keys) use the -E option.  To build using apps already built, use the -I option.  This is mainly
used when developing the script. To run the script automatically from the Windows task manager, use the -f 
option so the script won't pause and display a warning message about cloning repos.
```
run_cfastbundle [options]

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
