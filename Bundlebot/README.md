
#  Building Bundles

### Overview

This directory contains scripts for building FDS/Smokeview bundles for Windows, Linux and OSX FDS/Smokeview computing platforms. Two types of bundles are built.  Bundles are built every night using fds and smv repo revisions from the latest firebot pass. Bundles are also built whenever FDS and Smokeview are released.  In this case, revisions and tags for the fds and smv repos are specified.

Building a bundle consists of three steps: 
  1. Run firebot to generate FDS manuals, 
  2. Run smokebot to generate Smokeview manuals 
  3. Assemble applications, example files and manuals to generate the bundles.

These steps are described in more detail below.

### Preliminary Step

The bundling process erases and clones fresh copies of fds and repos.  So bundles should not be created within a directory tree where daily work is performed. This section gives steps for creating repo directories used by the bundle scripts.  This only needs to be performed once and is the same method firebot and smokebot uses to clone repos.  

Note, release bundles should be built on the same computer where nightly bundles are built to insure that compiler versions and OpenMPI libraries are consistent. 

To generate a set of repos, type the following commands:
1.  cd to your home directory and type mkdir FireModels_bundle
2.  git clone git@github.com:USERNAME/bot.git (where USERNAME is your github username) 
3.  cd bot/Scripts
4.  ./setup_repos.sh -a
5.  ./setup_repos.sh -w  this creates the wiki and web repos

Notes:

1. To update the repos just created at a later time, cd to bot/Scripts and type: ./update_repos.sh .
2. To clone directories on a Windows computer use \ not / and type setup_repos not setup_repos.sh .

### Bundling Steps

> [!CAUTION]
> Again, these bundle scripts erase and clone fresh copies of the fds and smv repos. You should not run these scripts in repos where you perform daily work.

1. cd to bot/Bundlebot/scripts
2. Configure the scripts.  edit the file BUNDLE_config.sh and define the environment variables: `BUNDLE_FDS_REVISION`, `BUNDLE_FDS_TAG`, `BUNDLE_SMV_REVISION` and `BUNDLE_SMV_TAG` . The variables below were defined using revisions for a firebot pass on Feb 9, 2024. The string test was added to the TAG environment variables so any test bundles created would not be configued with official ones.
```
export BUNDLE_FDS_REVISION=c1b5f1a
export BUNDLE_FDS_TAG=FDS-6.9.0test
export BUNDLE_SMV_REVISION=b837eeb
export BUNDLE_SMV_TAG=SMV-6.9.0test
```
3. Build the fds manuals. Run the script BUILD_fds_manuals.sh .  This script runs firebot using revisions and tags defined in BUNDLE_config.sh .  When a firebot is successful (no errors or warnings), documents are copied to the directory $HOME/.firebot/pubs and $HOME/.firebot/branch_name/pubs. At NIST this occurs every night. Tags are only created in the local fds and smv repos.  They are not pushed up to GitHub. If errors are discovered in the bundles that require more commits a tag does not need to be undone. Tagging is done by hand when the bundles are eventually published. It takes about seven hours to run firebot and build the fds manuals.
4. Build the smokeview manuals. Run the script BUILD_smv_manuals.sh .  This script runs smokebot using revisions and tags defined in BUNDLE_config.sh.
5. Build the bundle.  To build an official release, run the script `BUILD_release_bundle.sh` .  The same script can be run on a Linux and OSX computer.  While testing, run the script `BUILD_test_release.sh`. After building the bundles, these scripts upload them to the GitHub [test_bundles](https://github.com/firemodels/test_bundles) repository so that they can be tested before being published.  Edit this file and change the fds and smv hash and tags for a different release.
 




