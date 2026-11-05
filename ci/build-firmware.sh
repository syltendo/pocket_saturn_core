#!/bin/sh
# Build the CD block / SMPC firmware for the Pocket image (two .hex files the
# RTL reads). Called by .github/workflows/build.yml after the SMPC ROM
# (src/fpga/rtl/Saturn/SMPC/smpc.mif) has been fetched.
#
# Toolchain: LLVM 20 from apt.llvm.org (ld.lld >= 17 is required for
# --relax-gp; Ubuntu 22.04's LLVM 14 linker rejects the flag).
# Diagnostic build: build.sh runs under sh -x so the step log shows the exact
# linker script size and compile lines while the RAM overflow is chased.
set -e
if [ ! -x /usr/lib/llvm-20/bin/clang ]; then
  wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | sudo tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc >/dev/null
  . /etc/os-release
  echo "deb http://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME-20 main" | sudo tee /etc/apt/sources.list.d/llvm20.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq clang-20 lld-20 llvm-20 >/dev/null
fi
export LLVM=/usr/lib/llvm-20/bin
$LLVM/clang --version | head -1
$LLVM/ld.lld --version | head -1
cd "$(dirname "$0")/../src/fw/cdb"
SMPC_FW=1 CD_SRC=1 LLVM=$LLVM LD_LLD=$LLVM/ld.lld sh -x ./build.sh
ls -l ../../fpga/rtl/Saturn/CD/cdb_hle_pocket_fw.hex ../../fpga/rtl/Saturn/CD/cdb_hle_pocket_fw_1.hex
