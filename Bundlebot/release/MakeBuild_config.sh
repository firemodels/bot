#!/bin/bash
# This scripts obtains revisions and tags for a bundle.

base_tag=$1

repos="fds smv cad exp fig out"
CURDIR=`pwd`
gitroot=$CURDIR/../../..
cd $gitroot
gitroot=`pwd`
cd $CURDIR

cat << EOF
#!/bin/bash
# This scripts defines revisions and tags for a bundle.
# It is run by the other BUILD scripts.
# You do not need to run it.

EOF

for repo in $repos
do
./RepoConfig.sh $gitroot $repo $base_tag 
done
cat << EOF
# the lines below should not need to be changed

export GH_REPO=test_bundles
export GH_FDS_TAG=BUNDLE_TEST
export GH_SMOKEVIEW_TAG=BUNDLE_TEST
EOF
