#!/bin/sh
set -e

git push origin -f asahi filter-state 'refs/tags/v*-dts' 'refs/tags/v*-dts-raw'

