#  Building Bundles

This directory contains scripts for building FDS/Smokeview installtion bundles for Windows, Linux and OSX (Mac) computers.
Bundles are built nightly whenever firebot passes and whenever FDS and Smokeview is released.
Building a bundle consists of three steps: 1. run firebot to generate FDS manuals, 2. run smokebot to generate
Smokeview manuals and 3. assemble applications, example files and guides to generate the bundles.
These steps are outlined in more detail below.

### Bundling Steps

1. Run firebot on a Linux computer to generate FDS manuals. If firebot is successful, documents are copied to the
directory $HOME/.firebot/pubs and $HOME/.firebot/branch_name/pubs . At NIST this occurs nightly.
The manuals for the FDS 6.7.6 release were generated using the script `build_fds_manuals.sh`. This script runs
firebot with the options 
`-x 5064c500c -X FDS6.7.6` for specifying the fds revision and tag  and options `-y a2687cda4 -Y SMV6.7.16`  for 
specifying the smv repo revision and tag.
2. Run smokebot on a Linux computer to generate Smokeview manuals. Similarly if smokebot is successful,
documents are copied to `$HOME/.smokebot/pubs` and `$HOME/.smokebot/branch_name/pubs`. 
At NIST this occurs whenever the FDS and/or Smokeview source changes in the entral repo or once a day if the smokeview source has not changed.
Similary, the manuals for the SMV 6.7.16 release were generated using the script `build_smv_manuals.sh`. This script runs
smokebot with the options 
`-x 5064c500c -X FDS6.7.6` for specifying the fds revision and tag  and options `-y a2687cda4 -Y SMV6.7.16`  for 
specifying the smv repo revision and tag.
3. Run the script `run_bundlebot.sh` on a Linux or OSX computer or `run_bundlebot.bat` on a Windows computer
to build the applications and bundle.  These scripts upload the bundles to the 
[nightly builds google drive directory)](https://drive.google.com/drive/folders/1X-gRYGPGtcewgnNiNBuho3U8zDFVqFsC?usp=sharing)

To build a release bundle for fds repo tag FDS6.7.5 and smv repo tag SMV6.7.15 one would cd to the directory bot/Bundlebot and
then run the command
```
./run_bundlebot.sh -F FDS6.7.5 -S SMV6.7.15 -r
```
and on a PC
```
run_bundlebot -F FDS6.7.5 -S SMV6.7.15 -r
```

A nightly bundle on a Linux or OSX computer is generated similarly using
```
./run_bundlebot.sh 
```
The repo revisions are obtained from the last successful firebot runs.

Note, need to add info on files in $HOME/.bundle the bundle scripts need to build bundles (run time libraries etc).



