#  Building Bundles

Preliminary notes on building bundles.

This directory contains scripts for building FDS/Smokeview installation files or bundles bundles for Windows, Linux and OSX (Mac) computers.
Bundles are built nightly whenever firebot passes and whenever FDS and Smokeview is released.
Building a bundle consists of three steps: 1. run firebot to generate FDS manuals, 2. run smokebot to generate
Smokeview manuals and 3. assemble applications, example files and guides to generate the bundles.
These steps are outlined in more detail below.

### Bundling Steps

Warning: these scripts erase and clone fresh copies of the fds and smv repos.  You should only run these scripts in repos where you do not do daily work.

1. Run firebot on a Linux computer to generate FDS manuals. If firebot is successful, documents are copied to the
directory $HOME/.firebot/pubs and $HOME/.firebot/branch_name/pubs . At NIST this occurs nightly.
The manuals for the FDS 6.7.6 release were generated using the script `build_fds_manuals.sh`. This script runs
firebot with the options 
`-x 5064c500c -X FDS6.7.6` for specifying the fds revision and tag  and options `-y a2687cda4 -Y SMV6.7.16`  for 
specifying the smv repo revision and tag. The  parameter `-R release` is also passed to firebot to name the branch release.
It takes about seven hours to run smokebot and build the manuals.
2. Run smokebot on a Linux computer to generate Smokeview manuals. If smokebot is successful,
documents are copied to `$HOME/.smokebot/pubs` and `$HOME/.smokebot/branch_name/pubs`. 
At NIST this occurs whenever the FDS and/or Smokeview source changes in the central repo also also once a day.
The manuals for the SMV 6.7.16 release were generated using the script `build_smv_manuals.sh`. This script runs
smokebot with the options 
`-x 5064c500c -X FDS6.7.6` for specifying the fds revision and tag  and options `-y a2687cda4 -Y SMV6.7.16`  for 
specifying the smv repo revision and tag. The  parameter `-R release` is also passed to smokebot to name the branch release.
It takes about one hour to run smokebot and build the manuals.
3. Run the script `build_release.sh` on a Linux or OSX computer or `build_release.bat` on a Windows computer
to build the applications and bundle.  After building the bundles, these scripts upload them to the 
[nightly builds google drive directory)](https://drive.google.com/drive/folders/1X-gRYGPGtcewgnNiNBuho3U8zDFVqFsC?usp=sharing)

The bash script `build_release.sh` is used to build release bundles on a Linux or Mac computer.
It contains the following line for building the FDS6.7.6 and Smokeview 6.7.16 release bundle. Edit this
file and change the fds and smv hash and tags for a different release. `bundle_settings.sh` contains setttings such as
host names and email addresses particular to the site where the bundle is being generated. A sample settings script, `bundle_settings_sample`
is located in this directory.

```./run_bundlebot.sh -f -P $HOME/.bundle/bundle_settings.sh -R release -F 5064c500c -X FDS6.7.6 -S 485e0cd19 -Y SMV6.7.16 ```

Similarly, the windows batch file, `build_release.bat` contains the line

```run_bundlebot -c -R release -F 5064c500c -X FDS6.7.6 -S 485e0cd19 -Y SMV6.7.16```

for building a Windows bundle.  Edit this
file and change the fds and smv hash and tags for a different release.

### Summary

Warning: these scripts erase and clone fresh copies of the fds and smv repos.  You should only run these scripts in repos where you do not do daily work.

1. Edit build_fds_manuals.sh, build_smv_manuals.sh, build_release.sh and build_release.bat updating hashes and tags.  Commit these files.
2. Run build_fds_manuals.sh in firebot account.
3. Run build_smv_manuals.sh in smokebot account.
4. After manuals are built, run build_release.sh on both a Linux and Mac computer.  Run build_release.bat on a Mac.
 




