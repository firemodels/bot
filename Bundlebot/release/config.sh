#!/bin/bash
# This scripts defines revisions and tags for a bundle.
# It is run by other BUILD scripts to define the environment.
# ----------------------------
# repo environment variables

# CAD-6.9.0-0-gc5fd24b
export BUNDLE_CAD_REVISION=c5fd24b
export BUNDLE_CAD_TAG=CAD-9.0.1

# EXP-6.9.0-0-g8e390fd56-dirty
export BUNDLE_EXP_REVISION=8e390fd56
export BUNDLE_EXP_TAG=EXP-9.0.1

# FDS-6.9.0-64-gd005fa4f3
export BUNDLE_FDS_REVISION=d005fa4f3
export BUNDLE_FDS_TAG=FDS-9.0.1

# FIG-6.9.0-45-g5bdc65d
export BUNDLE_FIG_REVISION=5bdc65d
export BUNDLE_FIG_TAG=FIG-9.0.1

# OUT-6.9.0-0-g6b7ac2e39
export BUNDLE_OUT_REVISION=6b7ac2e39
export BUNDLE_OUT_TAG=OUT-9.0.1

# SMV-6.9.0-94-g227204856
export BUNDLE_SMV_REVISION=227204856
export BUNDLE_SMV_TAG=SMV-9.0.1

# ----------------------------
# github environment variables

export GH_REPO=test_bundles
export GH_FDS_TAG=BUNDLE_TEST
export GH_SMOKEVIEW_TAG=BUNDLE_TEST
