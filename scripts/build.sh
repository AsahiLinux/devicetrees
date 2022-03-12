#!/bin/sh
set -e

make $(find src/arm64/apple/ -name '*.dts' | sed -re 's/\.dts/.dtb/g')
