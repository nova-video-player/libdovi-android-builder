#!/bin/bash

# Build libdovi (the C API of dovi_tool's dolby_vision crate) as a static
# library for one Android ABI and install it into ../prebuilt/libdovi.
# Requires rustup (or cargo with the Android targets installed) and cargo-c.

while getopts "a:" opt; do
  case $opt in
    a)
      ARCH=$OPTARG ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ -z "${ARCH}" ]] ; then
  echo 'You need to input arch with -a ARCH.'
  echo 'Supported archs are:'
  echo -e '\tarm arm64 x86 x86_64'
  exit 1
fi

source ../../AVP/android-setup-light.sh

LOCAL_PATH=$($READLINK -f .)
mkdir -p ../prebuilt/libdovi
PREBUILT_DIR=$($READLINK -f ../prebuilt/libdovi)

LIBDOVI_TAG=libdovi-3.4.0
ANDROID_API=21

case "${ARCH}" in
  'arm')
    ARCH_TRIPLET='arm-linux-androideabi'
    ARCH_TRIPLET_VARIANT='armv7a-linux-androideabi'
    RUST_TARGET='armv7-linux-androideabi'
    ABI='armeabi-v7a' ;;
  'arm64')
    ARCH_TRIPLET='aarch64-linux-android'
    ARCH_TRIPLET_VARIANT=$ARCH_TRIPLET
    RUST_TARGET='aarch64-linux-android'
    ABI='arm64-v8a' ;;
  'x86')
    ARCH_TRIPLET='i686-linux-android'
    ARCH_TRIPLET_VARIANT=$ARCH_TRIPLET
    RUST_TARGET='i686-linux-android'
    ABI='x86' ;;
  'x86_64')
    ARCH_TRIPLET='x86_64-linux-android'
    ARCH_TRIPLET_VARIANT=$ARCH_TRIPLET
    RUST_TARGET='x86_64-linux-android'
    ABI='x86_64' ;;
  *)
    echo "Arch ${ARCH} is not supported."
    exit 1 ;;
esac

if [ -f "${PREBUILT_DIR}/lib/${ABI}/libdovi.a" ] && \
   [ -f "${PREBUILT_DIR}/include/libdovi/rpu_parser.h" ]; then
  echo "Already built for ${ABI}"
  exit 0
fi

# Prefer rustup proxies (Homebrew installs them outside ~/.cargo/bin), then
# ~/.cargo/bin for cargo-c.
for dir in /opt/homebrew/opt/rustup/bin /usr/local/opt/rustup/bin; do
  [ -x "${dir}/cargo" ] && export PATH=${dir}:${PATH}
done
[ -d "${HOME}/.cargo/bin" ] && export PATH=${PATH}:${HOME}/.cargo/bin

if ! command -v cargo > /dev/null 2>&1; then
  echo "cargo not found: install Rust with rustup (https://rustup.rs)."
  exit 1
fi
if ! cargo cinstall --version > /dev/null 2>&1; then
  echo "cargo-c not found: run 'cargo install cargo-c'."
  exit 1
fi
if command -v rustup > /dev/null 2>&1; then
  rustup target add ${RUST_TARGET}
fi

os=$(uname -s | tr '[:upper:]' '[:lower:]')
CROSS_PREFIX="${NDK_PATH}"/toolchains/llvm/prebuilt/${os}-x86_64/bin

set -eu

# cargo and the cc crate read per-target variables.
TARGET_ENV=$(echo ${RUST_TARGET} | tr 'a-z-' 'A-Z_')
TARGET_CC_ENV=$(echo ${RUST_TARGET} | tr '-' '_')
export CARGO_TARGET_${TARGET_ENV}_LINKER="${CROSS_PREFIX}/${ARCH_TRIPLET_VARIANT}${ANDROID_API}-clang"
export CARGO_TARGET_${TARGET_ENV}_AR="${CROSS_PREFIX}/llvm-ar"
export CC_${TARGET_CC_ENV}="${CROSS_PREFIX}/${ARCH_TRIPLET_VARIANT}${ANDROID_API}-clang"
export AR_${TARGET_CC_ENV}="${CROSS_PREFIX}/llvm-ar"

if [ ! -d dovi_tool ]; then
  git clone --depth 1 -b ${LIBDOVI_TAG} https://github.com/quietvoid/dovi_tool
fi

dir_name=build
DESTDIR=${LOCAL_PATH}/${dir_name}-${ABI}
rm -rf "${DESTDIR}"

echo "Build: calling cargo cinstall for ${RUST_TARGET}..."
cargo cinstall --release --locked \
  --manifest-path dovi_tool/dolby_vision/Cargo.toml \
  --features capi \
  --library-type staticlib \
  --target ${RUST_TARGET} \
  --target-dir "${LOCAL_PATH}/target" \
  --prefix / --libdir lib --includedir include \
  --destdir "${DESTDIR}"

echo "Copying to prebuilt directory..."
mkdir -p ${PREBUILT_DIR}/lib/${ABI} ${PREBUILT_DIR}/include
cp ${DESTDIR}/lib/libdovi.a ${PREBUILT_DIR}/lib/${ABI}/libdovi.a
# Debug info is most of the archive; symbols needed for linking are kept.
"${CROSS_PREFIX}/llvm-strip" --strip-debug ${PREBUILT_DIR}/lib/${ABI}/libdovi.a
rm -rf ${PREBUILT_DIR}/include/libdovi
cp -r ${DESTDIR}/include/libdovi ${PREBUILT_DIR}/include/
cp dovi_tool/LICENSE ${PREBUILT_DIR}/LICENSE
echo "Done!"
