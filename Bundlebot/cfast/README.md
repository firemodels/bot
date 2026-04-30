#  cfast bundle scripts

This directory contains scripts for building cfast bundles.

### Building a nightly bundle
1. cd into `FireModels_cbundle\bot\Bundlebot\cfast\nightly
2. type: `BuildCfastNightly.bat`

### Building a release bundle
1. cd into `FireModels_cbundle\bot\Bundlebot\cfast\release
2. edit the file `config.bat`
```
:: CFAST-7.7.5-104-g97584019a
set BUNDLE_CFAST_REVISION=97584019a
set BUNDLE_CFAST_TAG=CFAST-7.7.6test

:: SMV-6.10.6-559-ge69be0a13
set BUNDLE_SMV_REVISION=e69be0a13
set BUNDLE_SMV_TAG=SMV-6.10.7test
```


