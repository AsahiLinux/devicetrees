#!/bin/sh
set -e

git remote add state https://github.com/ijc/devicetree-conversion-state-v2
git remote add asahi https://github.com/asahilinux/linux
git fetch origin filter-state asahi-branch-base
git branch filter-state refs/remotes/origin/filter-state
