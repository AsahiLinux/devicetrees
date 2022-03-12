#!/bin/bash

set -e

cd $(dirname $0)/..

export SCRIPTS="$(dirname $(readlink -f "$0"))"

UPSTREAM=asahi
UPSTREAM_BRANCH=asahi/asahi
STATE=state
FILTERDIR=/mnt/ramtmp/git-rebase
MAINBRANCH=asahi

echo "Wiping state..."

rm -rf "$FILTERDIR"
rm -f filter.map.cur filter.map.new

echo "Updating upstreams..."
git fetch $UPSTREAM --tags
git fetch $STATE --tags --force

echo "Finding common base..."
base=
for i in $(git log --no-walk --tags="v[0-9]*.*[0-9]" --pretty="%d" \
        $UPSTREAM_BRANCH | grep "tag:" | sed s/'^ (tag: //' | cut -d',' -f1 |
        tr -d ')'); do
    if ! git rev-parse "${i}-dts" >/dev/null; then
        echo "$i: Missing"
        continue
    fi
    tag_hash="$(git rev-list -n 1 $i)"
    merge_base="$(git merge-base "$UPSTREAM_BRANCH" $i)"
    if [ "$tag_hash" != "$merge_base" ]; then
        echo "$i: Not a merge base"
        continue
    fi
    echo "$i: Found"
    base="$i"
    break
done

if [ -z "$base" ]; then
    echo >&2 "Unable to find common base"
    exit 1
fi

rm -f filter.map.cur filter.map.new

echo "Checking out $MAINBRANCH..."
git checkout $MAINBRANCH

echo "Resetting state branches..."
git branch -f upstream/master refs/tags/${base}
git branch -f upstream/dts refs/tags/${base}-dts-raw

echo "Merging filter state..."
git branch -f filter-state-prev filter-state
git branch -f filter-state-merge filter-state
git checkout filter-state-merge
cp filter.map filter.map.cur
git reset --hard refs/remotes/$STATE/filter-state
cat filter.map filter.map.cur | sort | uniq >filter.map.new
mv -f filter.map.new filter.map
rm -f filter.map.cur
git add filter.map
git commit --allow-empty -m "Merge"
git branch -f filter-state HEAD

echo "Resetting $MAINBRANCH branch..."
git checkout $MAINBRANCH
git reset --hard ${base}-dts
git merge --no-edit origin/scripting

git rev-parse $UPSTREAM_BRANCH >.git/FETCH_HEAD

export FILTER_BRANCH_ARGS="-d $FILTERDIR"

./scripts/filter.sh

git checkout $MAINBRANCH

export GIT_AUTHOR_DATE=$(git log -1 --format=%ad $UPSTREAM_BRANCH)
if [ ! "${GIT_AUTHOR_DATE}" ] ; then
    echo >&2 "Unable to determine author date for merge"
    exit 1
fi
git merge --no-edit upstream/dts
git clean -fdqX
