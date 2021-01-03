#!/bin/bash

# this uses the GCC 9 toolchain
# main toolchain:
# https://github.com/kdrag0n/aarch64-elf-gcc.git
# for 32bit cross-compiling:
# https://github.com/kdrag0n/arm-eabi-gcc.git
# when building under WSL make sure the distro uses WSL 2

# Update submodules
git submodule update --recursive --init

export KBUILD_BUILD_USER="user"
export KBUILD_BUILD_HOST="build"
export ARCH="arm64"
export SUBARCH="arm64"
export TRIPLET=$(basename $HOME/aarch64-elf-gcc/bin/*gcc | sed 's|gcc$||g')
export TRIPLET_ARM32="arm-eabi-"
export CROSS_COMPILE="$HOME/aarch64-elf-gcc/bin/$TRIPLET"
export CROSS_COMPILE_ARM32="$HOME/arm-eabi-gcc/bin/$TRIPLET_ARM32"
export KBUILD_OUTPUT="$(pwd)/out"
export KBUILD_BUILD_USER="user"
export KBUILD_BUILD_HOST="build"

if [ "${USE_CCACHE}" == 1 ] && [ -x "${CCACHE_EXEC}" ];
then
    CROSS_COMPILE="${CCACHE_EXEC} ${CROSS_COMPILE}"
    CROSS_COMPILE_ARM32="${CCACHE_EXEC} ${CROSS_COMPILE_ARM32}"
fi

echo
echo "Cleanup output dir"
echo

rm -rf out
make clean && make mrproper
mkdir -p out

echo
echo "Build kernel"
echo

#Make config
make O=out ARCH=arm64 nb1_defconfig

CURRENT_BRANCH=$(git branch --show-current)
CURRENT_BRANCH_CLEAN=${CURRENT_BRANCH//_/}
CURRENT_BRANCH_CLEAN=${CURRENT_BRANCH_CLEAN// /_}
CURRENT_BRANCH_CLEAN=${CURRENT_BRANCH_CLEAN////_}
CURRENT_BRANCH_CLEAN=${CURRENT_BRANCH_CLEAN//[^a-zA-Z0-9_]/}-

LAST_COMMIT=$(git rev-parse --verify --short=8 HEAD)

#Build kernel
make -j$(nproc --all) O=out \
    ARCH=arm64 \
    LOCALVERSION=-gcc-${CURRENT_BRANCH_CLEAN}$(date +"%d%m%y%H%M")-$LAST_COMMIT $*
