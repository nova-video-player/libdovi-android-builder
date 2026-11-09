#!/bin/bash

set -e

for ARCH in arm arm64 x86 x86_64; do
  ( . build.sh -a ${ARCH} )
done
