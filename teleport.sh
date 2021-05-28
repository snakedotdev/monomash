#!/bin/bash

## bring a $branch from old repo over to monorepo
##
## teleport.sh <oldrepo path> <oldrepo branch> <monorepo path> <monorepo branch>
##
## Example:
## teleport.sh ~/pete/oldrepo myfeature ~/pete/monorepo main
##

set -exu -o pipefail

oldname=$(basename $1)
branch=$2
patchfile=~/teleport-$oldname-$branch.patch

pushd $1
git switch $branch
git diff $4..$branch > $patchfile
popd

pushd $3
git checkout $4
git clean -di
git checkout -b $branch
pushd $oldname
patch -p1 < $patchfile
git add .
popd
git commit -am "Squashed branch $branch from old repo $oldname"
git push origin $branch
popd
