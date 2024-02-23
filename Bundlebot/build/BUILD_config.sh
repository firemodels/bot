#!/bin/bash
# This scripts defines revisions and tags for a bundle.
# It is run by the other BUILD scripts. 
# You do not need to run it.

# firebot pass 2/23/2024
# FDS-6.8.0-1561-g50afa7f/master
# SMV-6.8.0-2075-g38047e9/master

export BUNDLE_FDS_REVISION=50afa7f
export BUNDLE_FDS_TAG=FDS-6.9.0
export BUNDLE_SMV_REVISION=38047e9
export BUNDLE_SMV_TAG=SMV-6.9.0

# lines below should not need to be changed

GH_REPO=test_bundles
GH_FDS_TAG=BUNDLE_TEST
GH_SMOKEVIEW_TAG=BUNDLE_TEST

export GH_REPO
export GH_FDS_TAG
export GH_SMOKEVIEW_TAG
