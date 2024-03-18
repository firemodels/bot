@echo off
:: This scripts defines revisions and tags for a bundle.
:: It is run by the other BUILD scripts.
:: You do not need to run it.

set BUNDLE_FDS_REVISION=a33726c82
set BUNDLE_FDS_TAG=FDS-6.9.0

set BUNDLE_SMV_REVISION=d5e9e21f2
set BUNDLE_SMV_TAG=SMV-6.9.0

set BUNDLE_CAD_REVISION=c5fd24b
set BUNDLE_CAD_TAG=CAD-6.9.0

set BUNDLE_EXP_REVISION=8e390fd56
set BUNDLE_EXP_TAG=EXP-6.9.0

set BUNDLE_FIG_REVISION=933b82a
set BUNDLE_FIG_TAG=FIG-6.9.0

set BUNDLE_OUT_REVISION=6b7ac2e39
set BUNDLE_OUT_TAG=OUT-6.9.0

:: lines below should not need to be changed

set GH_REPO=test_bundles
set GH_FDS_TAG=BUNDLE_TEST
set GH_SMOKEVIEW_TAG=BUNDLE_TEST
