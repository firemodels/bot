
#  Building Bundles

### Overview

This directory contains scripts for building FDS/Smokeview bundles on Windows, Linux and OSX computing platforms. Two types of bundles are built.  Bundles are built every night using fds and smv repo revisions from the latest firebot pass. Bundles are also built whenever FDS and Smokeview are released.  In this case, revisions and tags for the fds and smv repos are specified.

Building a bundle consists of three steps: 
  1. Run firebot to generate FDS manuals.
  2. Run smokebot to generate Smokeview manuals. 
  3. Assemble applications, example files and manuals to generate the bundles.

These steps are described in more detail below.

### Bundling Steps

> [!CAUTION]
> Bundle scripts erase and clone fresh copies of the fds and smv repos. These scripts should not be run in repos where daily work is performed.  At NIST Linux and OSX bundles are built in the firebot user account under the directory Firemodels_bundle . 

1. switch to the firebot account (type: `sudo su - firebot`)  and cd to Firemodels_bundle/bot/Bundlebot/scripts
2. **Configure the scripts.**  Edit the script `BUNDLE_config.sh` and define the environment variables: `BUNDLE_FDS_REVISION`, `BUNDLE_FDS_TAG`, `BUNDLE_SMV_REVISION` and `BUNDLE_SMV_TAG` . The variables below were defined using revisions for a firebot pass on Feb 9, 2024. The string `test` was appended to the TAG environment variables so that any test bundles created would not be confused with official ones.
```
export BUNDLE_FDS_REVISION=c1b5f1a
export BUNDLE_FDS_TAG=FDS-6.9.0test
export BUNDLE_SMV_REVISION=b837eeb
export BUNDLE_SMV_TAG=SMV-6.9.0test
```
3. **Build the fds manuals.** Run the script `BUILD_fds_manuals.sh` in the firebot account.  This script runs firebot using revisions and tags defined in BUNDLE_config.sh and takes about 7 hours to complete.  When a firebot run is successful (no errors or warnings), documents are copied to the directory $HOME/.firebot/pubs and $HOME/.firebot/branch_name/pubs.  Note, tags are only created in the local fds and smv repos.  They are not pushed up to GitHub. So, if errors are discovered in the bundles that require more commits, a tag does not need to be undone. Tagging is done by hand when the bundles are eventually published.
   1. switch to the firebot account (type: `sudo su - firebot`)
   2. `cd Firemodels_bundle/bot/Bundlebot/scripts`
   3. `./Build_fds_manuals.sh`
    
5. **Build the smokeview manuals.** Run the script BUILD_smv_manuals.sh in the smokebot account.  Since firebot and smokbot are run in two different accounts, they can be run at the same time.  This script runs smokebot using revisions and tags defined in BUNDLE_config.sh.
   1. switch to the smokebot account (type: `sudo su - smokebot`)
   2. `cd Firemodels_bundle/bot/Bundlebot/scripts`
   3. `./Build_smv_manuals.sh`

7. **Build the bundle.**  Run the script `BUILD_release_bundle.sh` in the firebot account (type: `sudo su - firebot` to switch accounts).  The same script can be run on a Linux and OSX computer.  While testing, run the script `BUILD_test_release.sh`. After building the bundles, these scripts upload them to the GitHub [test_bundles](https://github.com/firemodels/test_bundles) repository so that they can be tested before being published.  Edit this file and change the fds and smv hash and tags for a different release.
 




