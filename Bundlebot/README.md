
#  Building Bundles

### Overview

This directory contains scripts for building FDS/Smokeview bundles on Windows, Linux and OSX computing platforms. 

Building a bundle consists of three steps: 
  1.Build FDS manuals (run the script `BUILD_fds_manuals.sh`).
  2. Build Smokeview manuals (run the script `BUILD_smv_manuals.sh`). 
  3. Assemble applications, example files and manuals to generate the bundles (run the script `BUILD_release_bundle.sh` or `BUILD_test_bundle.sh`).

These steps are described in more detail below.

### Setting Revisions and Tags  

The scripts for building FDS and Smokeview manuals and building the bundle use the same revision and tag parameters.  These parmameters are defined in the script `BUNDLE_config.sh` .  The following steps to define these parameters can be performed in your own bot repo as long as you commit the changes and push them up to the central repo.
1. cd to bot/Bundlebot/scripts
2. Edit the script `BUNDLE_config.sh` and define the environment variables: `BUNDLE_FDS_REVISION`, `BUNDLE_FDS_TAG`, `BUNDLE_SMV_REVISION` and `BUNDLE_SMV_TAG` for the revision and tag you wish to build a bundle for.
3. Commit and push up these changes to github .

The variables below were defined using revisions for a firebot pass on Feb 9, 2024. The string `test` was appended to the TAG environment variables so that any test bundles created would not be confused with official ones.
```
export BUNDLE_FDS_REVISION=c1b5f1a
export BUNDLE_FDS_TAG=FDS-6.9.0test
export BUNDLE_SMV_REVISION=b837eeb
export BUNDLE_SMV_TAG=SMV-6.9.0test
```

### Bundling Steps

> [!CAUTION]
> Bundle scripts erase and clone fresh copies of the fds and smv repos. These scripts should not be run in repos where daily work is performed.  At NIST, Linux and OSX bundles are built in the firebot user account in the directory Firemodels_bundle/bot/Bundlebot/scripts . 

1. **Build the FDS manuals.** Run the script `BUILD_fds_manuals.sh` in the firebot account.  This script runs firebot using revisions and tags defined in BUNDLE_config.sh and takes about 7 hours to complete.  Note, tags are only created in the local fds and smv repos.  They are not pushed up to GitHub. So a tag does not need to be undone if errors are discovered in the bundles that require more commits, . Tagging may be performed after the bundles are published.
   1. switch to the firebot account (type: `sudo su - firebot`)
   2. `cd Firemodels_bundle/bot/Bundlebot/scripts`
   3. `./Build_fds_manuals.sh`
    
2. **Build the smokeview manuals.** Smokeview manuals are built similarly to the FDS manuals.  Run the script BUILD_smv_manuals.sh in the smokebot account.  Since firebot and smokebot are run in two different accounts, they can be run at the same time.  This script runs smokebot using revisions and tags defined in BUNDLE_config.sh. (Note: check to see if BUILD_smv_manuals.sh can be run in the firebot account - this would simplify the workflow)
   1. switch to the smokebot account (type: `sudo su - smokebot`)
   2. `cd Firemodels_bundle/bot/Bundlebot/scripts`
   3. `./Build_smv_manuals.sh`

3. **Build the bundle.**  After the FDS and smokeview manuals are built, run the script `BUILD_release_bundle.sh` in the firebot account (type: `sudo su - firebot` to switch accounts).  The same script can be run on a Linux and OSX computer.  While testing, run the script `BUILD_test_release.sh`. After building the bundles, these scripts upload them to the GitHub [test_bundles](https://github.com/firemodels/test_bundles) repository so that they can be tested before being published.  Edit this file and change the fds and smv hash and tags for a different release.
   1. switch to the firebot account (type: `sudo su - firebot`)
   2. `cd Firemodels_bundle/bot/Bundlebot/scripts`
   3. type: `./Build_release_bundle.sh` if building an `official` bundle, type `./Build_test_bundle.sh` if building a test bundle.  The only difference between these two options is where the bundles are uploaded. 
 




