#!/bin/bash

# Merge multiple repositories into one big monorepo. Migrates every branch in
# every subrepo to the eponymous branch in the monorepo, with all files
# (including in the history) rewritten to live under a subdirectory.
#
# To use a separate temporary directory while migrating, set the GIT_TMPDIR
# envvar.
#
# To access the individual functions instead of executing main, source this
# script from bash instead of executing it.

${DEBUGSH:+set -x}
if [[ "$BASH_SOURCE" == "$0" ]]; then
	is_script=true
	set -eu -o pipefail
else
	is_script=false
fi

# Default name of the mono repository (override with envvar)
: "${MONOREPO_NAME=core}"

# Monorepo directory
monorepo_dir="$PWD/$MONOREPO_NAME"

### merge a branch into a subdir, preserving history. this is the magic ###
function mash {

    local b d moved_something

    b=$1 # e.g. master
    d=$2 # e.g. my-source-repo

    echo "Mashing $b of $d"

    git switch -c mash "$d/$b"

    tmpdir=$(mktemp -d tmp.XXXX)
    moved_something="false"
    for f in * .*; do
        if [[ "$f" != .git && "$f" != "$tmpdir" && "$f" != "." && "$f" != ".." ]]; then
            git mv -k "$f" "$tmpdir"   
            moved_something="true"
        fi
    done

    if [ "$moved_something" == "true" ]; then
        mkdir -p "$(dirname "$d")"
        git mv "$tmpdir" "$d"
        git commit -m "Moving contents of $d to subdir on branch $b."
    else
        rmdir "$tmpdir"
    fi
    git checkout "$b"
    git merge --allow-unrelated-histories -s recursive -X no-renames --no-ff -m "Merging repo $d to branch $b." mash

    # use -D since we have merged but will not push back to source repo
    git branch -D mash

    echo "Done mashing $b of $d"
}

##### FUNCTIONS

# Silent pushd/popd
pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

function read_repositories {
	sed -e 's/#.*//' | grep .
}

# Simply list all files, recursively. No directories.
function ls-files-recursive {
	find . -type f | sed -e 's!..!!'
}

# List all branches for a given remote
function remote-branches {
	# With GNU find, this could have been:
	#
	#   find "$dir/.git/yada/yada" -type f -printf '%P\n'
	#
	# but it's not a real shell script if it's not compatible with a 14th
	# century OS from planet zorploid borploid.

	# Get into that git plumbing.  Cleanest way to list all branches without
	# text editing rigmarole (hard to find a safe escape character, as we've
	# noticed. People will put anything in branch names).
	pushd "$monorepo_dir/.git/refs/remotes/$1/"
	ls-files-recursive
	popd
}

# add a branch to an upstream remote
# XXX only origin
add-upstream-branch () {
    if ! git rev-parse -q --verify "$1"; then
        git branch $1 $2
        git push origin $1
    else
        echo "Upstream branch $1 already exists"
        return 1
    fi
}

# Create a monorepository in a directory "core". Read repositories from STDIN:
# one line per repository, with two space separated values:
#
# 1. The (git cloneable) location of the repository
# 2. The name of the target directory in the core repository
function create-mono {
	if [[ -d "$MONOREPO_NAME" ]]; then
		echo "Target repository directory $MONOREPO_NAME already exists." >&2
		return 1
	fi
	mkdir "$MONOREPO_NAME"
	pushd "$MONOREPO_NAME"
	git init
	
	# This directory will contain all final tag refs (namespaced)
	mkdir -p .git/refs/namespaced-tags

	read_repositories | while read repo name folder; do

		if [[ -z "$name" ]]; then
			echo "pass REPOSITORY NAME pairs on stdin" >&2
			return 1
		elif [[ "$name" = */* ]]; then
			echo "Forward slash '/' not supported in repo names: $name" >&2
			return 1
		fi

                if [[ -z "$folder" ]]; then
			folder="$name"
                fi

		if [[ -z $(git remote | grep $name) ]]; then
		    echo "Merging in $repo.." >&2
    		git remote add "$name" "$repo"
		fi
		echo "Fetching $name.." >&2 
		git fetch -q "$name"

		# Now we've got all tags in .git/refs/tags: put them away for a sec
		if [[ -n "$(ls .git/refs/tags)" ]]; then
			mv .git/refs/tags ".git/refs/namespaced-tags/$name"
		fi

		# Merge every branch from the sub repo into the mono repo, into a
		# branch of the same name (create one if it doesn't exist).
		remote-branches "$name" | while read branch; do
			if git rev-parse -q --verify "$branch^{commit}"; then
				# Branch already exists, just check it out (and clean up the working dir)
				git checkout -q "$branch"
				git checkout -q --
				git clean -f -d
			else
				# Create a fresh branch with an empty root commit"
				git checkout -q --orphan "$branch"
				# The ignore unmatch is necessary when this was a fresh repo
				git rm -rfq --ignore-unmatch .
				git commit -q --allow-empty -m "Root commit for monorepo's $branch branch"
			fi
            mash $branch $name
		done
	done

	# Restore all namespaced tags
	rm -rf .git/refs/tags
	mv .git/refs/namespaced-tags .git/refs/tags
}

if [[ "$is_script" == "true" ]]; then
	create-mono "${1:-}"
fi
