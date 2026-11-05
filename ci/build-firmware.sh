#!/bin/sh
# Build the CD block / SMPC firmware for the Pocket image (two .hex files the
# RTL reads). Called by .github/workflows/build.yml after the SMPC ROM
# (src/fpga/rtl/Saturn/SMPC/smpc.mif) has been fetched.
#
# Toolchain: LLVM 21 from apt.llvm.org.
#  - ld.lld >= 17 is required for --relax-gp (Ubuntu 22.04's LLVM 14 rejects it).
#  - The image is size-critical: it must fit 88 KB (WORDS 22528). Measured
#    overflows of the final section: clang 18 +6,380 B, clang 20 +3,052 B
#    (with LENGTH correctly set to 90112). The author builds with current
#    Homebrew LLVM, so track the newest stable clang.
set -e
if [ ! -x /usr/lib/llvm-21/bin/clang ]; then
  wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | sudo tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc >/dev/null
  . /etc/os-release
  echo "deb http://apt.llvm.org/$VERSION_CODENAME/ llvm-toolchain-$VERSION_CODENAME-21 main" | sudo tee /etc/apt/sources.list.d/llvm21.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq clang-21 lld-21 llvm-21 >/dev/null
fi
export LLVM=/usr/lib/llvm-21/bin
$LLVM/clang --version | head -1
$LLVM/ld.lld --version | head -1
cd "$(dirname "$0")/../src/fw/cdb"
# CD_SRC_L2=0: the author's own size knob (build.sh header: leaving out the
# second read-ahead level spares CD RAM). With L2 in, the image is ~3 KB over
# the 88 KB RAM with clang 20/21; the knob is the documented way to fit it.
# SMPC_DEFS=-Oz: build.sh appends SMPC_DEFS after its -Os flags, so -Oz wins.
# With L2 off the image was still 2,128 B over; -Oz is the remaining squeeze.
if ! SMPC_FW=1 CD_SRC=1 CD_SRC_L2=0 SMPC_DEFS=-Oz LLVM=$LLVM LD_LLD=$LLVM/ld.lld sh ./build.sh; then
  echo '--- firmware link failed; per-object section sizes ---'
  $LLVM/llvm-size -A obj/*.o || true
  exit 1
fi
ls -l ../../fpga/rtl/Saturn/CD/cdb_hle_pocket_fw.hex ../../fpga/rtl/Saturn/CD/cdb_hle_pocket_fw_1.hex
