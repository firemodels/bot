#  Building Bundles

This directory contains scripts for building nightly and releasebundles (installation files) on Windows, Linux and OSX (Mac) computers. 
`run_bundlebot.sh` is used to build Linux and OSX bundles and `run_bundlebot.bat` is used to build a Windows 
bundle. These scripts use applications (FDS, Smokeview and Smokeview utilities) built by firebot, manuals 
( FDS and Smokeview User, Verification/Validation and Technical guides) built by firebot and smokebot and 
other files found in the bot, fds and smv repos.
Applications for Linux/OSX bundles are built by `firebot.sh`. 
Applications for a Windows bundle are built by `make_apps.bat`
Manuals are built by firebot and smokebot run on a Linux computer.

Building a bundle consists of three steps: 1. run firebot to generate FDS manuals, 2. run smokebot to generate
Smokeview manuals and 3. build applications and the the bundle.
These steps are outlined in more detail below.

### Bundling Steps

1. Run firebot on a Linux computer to generate FDS manuals. If firebot is successful, documents are copied to the
directory $HOME/.firebot/pubs . At NIST this occurs nightly.
2. Run smokebot on a Linux computer to generate Smokeview manuals. Similarly if smokebot is successful,
documents are copied to $HOME/.smokebot/pubs. 
At NIST this occurs whenever FDS and/or Smokeview source changes or at least once a day if the smokeview source has not changed.
3. Run the script `run_bundlebot.sh` on a Linux or OSX computer or `run_bundlebot.bat` on a Windows computer
to build the applications and bundle.  

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
./run_bundlebot.sh -F FDS6.7.5 -S SMV6.7.15 -r
```
The repo revisions are obtained from the last successful firebot runs.



