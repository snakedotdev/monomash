#!/bin/bash
## bring a $branch from old repo over to monorepo
##
## teleport.sh <oldrepo path> <oldrepo branch> <oldrepo main branch> <monorepo path> <monorepo branch> <path-in-monorepo>
##
## Example:
## teleport.sh ~/pete/oldrepo myfeature develop ~/pete/monorepo main ~/pete/monorepo/oldrepo
#              1              2         3       4               5     6
##
set -exu -o pipefail
oldname=$(basename $1)
branch=$2
resolved_branch=$(echo $2 | sed s:/:_:g)
patchfile=~/teleport-$oldname-${resolved_branch}.patch
echo $patchfile
pushd $1
git switch $branch
git diff --binary $3..$branch > $patchfile
popd
pushd $4
git checkout $5
git clean -di
git checkout -b $branch
pushd $oldname
git apply -p1 $patchfile --directory $6
#patch -p1 < $patchfile
git add .
popd
git commit -am "Squashed branch $branch from old repo $oldname"
git push origin $branch
popd
