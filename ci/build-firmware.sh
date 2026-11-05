#!/bin/sh
# Build the CD block / SMPC firmware for the Pocket image (two .hex files the
# RTL reads). Called by .github/workflows/build.yml after the SMPC ROM
# (src/fpga/rtl/Saturn/SMPC/smpc.mif) has been fetched.
# Needs: clang, ld.lld >= 17 (--relax-gp, RISC-V GP relaxation), llvm-objcopy,
# llvm-size, python3. Ubuntu 24.04's LLVM 18 is fine; Ubuntu 22.04's LLVM 14
# ld.lld rejects --relax-gp.
set -e
cd "$(dirname "$0")/../src/fw/cdb"
SMPC_FW=1 CD_SRC=1 LLVM=/usr/bin LD_LLD=/usr/bin/ld.lld sh ./build.sh
ls -l ../../fpga/rtl/Saturn/CD/cdb_hle_pocket_fw.hex ../../fpga/rtl/Saturn/CD/cdb_hle_pocket_fw_1.hex
