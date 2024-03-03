#!/bin/bash
# This scripts defines revisions and tags for a bundle.
# It is run by the other BUILD scripts. 
# You do not need to run it.

# revisions from 3/3/2024 firebot pass
# FDS-6.8.0-1640-g80124a6/master
# SMV-6.8.0-2108-g4a5edb7/master

export BUNDLE_FDS_REVISION=80124a6
export BUNDLE_FDS_TAG=FDS-6.9.0
export BUNDLE_SMV_REVISION=4a5edb7
export BUNDLE_SMV_TAG=SMV-6.9.0

# lines below should not need to be changed

GH_REPO=test_bundles
GH_FDS_TAG=BUNDLE_TEST
GH_SMOKEVIEW_TAG=BUNDLE_TEST

export GH_REPO
export GH_FDS_TAG
export GH_SMOKEVIEW_TAG
