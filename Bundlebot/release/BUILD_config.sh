#!/bin/bash
# This scripts defines revisions and tags for a bundle.
# It is run by the other BUILD scripts. 
# You do not need to run it.

# FDS-6.8.0-1732-g633956926
# SMV-6.8.0-2184-g1225e3df7

export BUNDLE_FDS_REVISION=633956926
export BUNDLE_FDS_TAG=FDS-6.9.1test

export BUNDLE_SMV_REVISION=1225e3df7
export BUNDLE_SMV_TAG=SMV-6.9.1test

export BUNDLE_CAD_REVISION=c5fd24b
export BUNDLE_CAD_TAG=CAD-6.9.1test

export BUNDLE_EXP_REVISION=8e390fd56
export BUNDLE_EXP_TAG=EXP-6.9.1test

export BUNDLE_FIG_REVISION=933b82a
export BUNDLE_FIG_TAG=FIG-6.9.1test

export BUNDLE_OUT_REVISION=6b7ac2e39
export BUNDLE_OUT_TAG=OUT-6.9.1test

# the line below should not need to be changed

source GITHUB_config.sh
