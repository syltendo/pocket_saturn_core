# Building the Saturn core for the Pocket (v0.1, source-only release)

akoaysigod's `pocket_saturn_core` v0.1 (2026-11-04) ships no installable build:
the release has no assets, the repo has no `dist/` tree and no compiled
firmware, and the core is not in the openFPGA Library. This fork adds the
missing pieces and a GitHub Actions workflow (`.github/workflows/build.yml`,
manual dispatch) that produces an installable SD-card zip. Nothing upstream
was modified: the additions are `dist/`, `.github/` and this file, plus two
files fetched/generated at build time (below).

## What was missing, and where each piece comes from

- **CD/SMPC firmware** (`src/fpga/rtl/Saturn/CD/cdb_hle_pocket_fw.hex` +
  `_1.hex`): built by the author's own `src/fw/cdb/build.sh`
  (`SMPC_FW=1 CD_SRC=1`) with clang/lld (LLVM >= 17: the link uses `--relax-gp`). Its one external input is the SMPC
  MCU ROM, `smpc.mif`, which the author develops against but does not ship.
  The port's README pins the upstream base to Saturn_MiSTer commit `9aa9449`
  (2026-10-19), and that repo does ship the file
  (`rtl/Saturn/SMPC/smpc.mif`) — the workflow fetches it from that exact
  commit. It is translated to C at build time and never packaged.
- **Quartus project**: complete as shipped (all 85 files referenced by the
  QIP chain are in the repo). Device 5CEBA4F23C8, project created with
  Quartus 18.1 → the workflow compiles with `raetro/quartus:18.1` in Docker,
  `quartus_sh --flow compile ap_core` in `src/fpga`.
- **`dist/` tree** (the APF JSONs + images): written for this build from the
  core's own glue RTL, following the conventions of the same author's PSX
  core release:
  - `data.json` slots from `src/fw/cdb/cd_src.c` (cue = 14, audio track 1 =
    15, disc files = 16..47), `pocket_rtl/pk_loader.sv` (BIOS at 0x00000000,
    internal backup RAM 0x10000000, backup cartridge 0x20000000, cartridge
    ROM 0x30000000) and `pocket_rtl/pk_save.sv` (save slots 2 and 3,
    parameters 0xA4).
  - `interact.json` from `pocket_rtl/pk_settings.sv`: Reset, Cartridge,
    Region, Timing, VDP1 mesh blur, Deinterlacing, Button mapping (presets
    from `pk_pad.sv`), plus the four non-persistent debug variables of the
    A6/A7 build (ids 8–11).
  - `video.json`: the 8 scaler modes of `glue/av_video.sv`
    (640/704 × 240/256 progressive, 480/512 interlaced), 4:3.
  - `core.json`: `sleep_supported: false` (the top level ties save states
    off), Dock supported.
  - Banner/icon: Sega Saturn console photo by Evan-Amos (Wikimedia Commons,
    CC BY-SA), converted with the author's `tools/png2pocket.py`.
  - `Assets/saturn/akoaysigod.Saturn/BIOS (no disc).json`: empty instance so
    the core can boot straight to the BIOS menu.

## Using the result

Unzip at the SD card root. Add your own Saturn BIOS as
`Assets/saturn/common/boot.rom` (512 KB) and games as cue/bin sets in
`Assets/saturn/common/<Game>/`. Build one instance JSON per game with
Pocket Sync (the core ships an `instance-packager.json`), or by hand:
slot 14 = the `.cue`, slots 16, 17, … = the cue's files in order.

Status: **test build**. The author has not published or endorsed this build;
timing closure and on-hardware behaviour are unverified until tested on a
real Pocket.

## Build outcome (2026-11-05) — PARKED at the owner's request after 15 CI runs

No installable bitstream yet. The firmware problem is SOLVED; the FPGA fit is not.

Firmware (runs 1–7): builds and links with **LLVM 21** (apt.llvm.org) plus the
author's own env knobs `CD_SRC_L2=0` and `SMPC_DEFS=-Oz` — no source edits.
Measured final-section overflows before the knobs: clang 18 +6,380 B,
clang 20 +3,052 B, clang 21 +2,984 B, +L2 off +2,128 B, +Oz = fits.
`ci/build-firmware.sh` encodes all of this.

Fit (device 5CEBA4F23C8: 1,848 LABs): every full compile missed by single
digits. Best result **1,850 LABs (run 12)** with the configuration now
restored in ap_core.qsf: author's settings + FITTER_EFFORT STANDARD FIT,
single SEED 19 (the author's own line; a duplicate SEED added earlier in the
file was silently overridden — removed), `POCKET_ARB_LEAN=1` (the author's
Pocket-build option: backup port reads single words), and `A6_DBG` removed
(diagnostic build: debug squares + 4 tuning toggles; its interact vars 8–11
were also dropped from dist). One RTL patch was needed for the A6-less build:
`src/fpga/glue/vdp1fb_ext.sv` — the A7 branch connected the A6 debug ports
unconditionally; they are now `ifdef A6_DBG`-gated, mirroring the author's
non-A7 branch (A5-path bit-rot fix).
Other attempts: seed 3 = 1,862; +CUT_VDP2_2048 = 1,856; +CUT_SCU_DSTP +
CUT_SCU_ABUSWR (run 15) = 1,853; physical synthesis EXTRA = 1,869 (worse).
The author's own build presumably fits via a different Quartus point release
or local settings not in the repo (unverified). To resume: dispatch the
workflow on main; the dist/ tree and packaging are ready, so a fitting
compile produces the installable zip with no further work.
