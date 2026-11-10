#!/bin/bash

set -e

# Building needs Rust: skip it when all prebuilt libs already exist.
PREBUILT_DIR=../prebuilt/libdovi/lib
if [ -f "${PREBUILT_DIR}/armeabi-v7a/libdovi.a" ] && \
   [ -f "${PREBUILT_DIR}/arm64-v8a/libdovi.a" ] && \
   [ -f "${PREBUILT_DIR}/x86/libdovi.a" ] && \
   [ -f "${PREBUILT_DIR}/x86_64/libdovi.a" ]; then
  echo "All libdovi prebuilt libs already exist, skipping"
  exit 0
fi

for ARCH in arm arm64 x86 x86_64; do
  ( . build.sh -a ${ARCH} )
done
