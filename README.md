# Black & White (2001) on Linux 🐮

Get **Black & White** — Peter Molyneux / Lionhead's god game — running **fullscreen with
correct graphics** on modern Linux, including the tricky **hybrid AMD + NVIDIA laptops**
where it normally renders see-through or won't start at all.

This repo is just the **installer + launchers**. You bring your own copy of the game.

## ⚖️ You need your own copy
Black & White is not sold digitally anywhere, but it's a game many of us own on disc.
**This project does not include the game, the serial key, or EA's patches** — you supply
the disc/ISO you own, and the installer downloads the community patches for you.

## Requirements
- A Linux box with a reasonably modern GPU (AMD, Intel, NVIDIA, or a hybrid laptop)
- Your **Black & White disc or ISO** + your **serial key**
- Packages: `wine`, `gamescope`, `winetricks`, `wmctrl`, `cabextract`, plus 32-bit Vulkan
  + Mesa drivers (the installer grabs these on Arch automatically)

## Install
```bash
git clone https://github.com/87611JoeJohn/black-and-white-linux
cd black-and-white-linux
bash install.sh /path/to/your/BlackAndWhite.iso
```
Click through the game's setup and the two patch windows when they pop up. When it's done,
launch **Black & White** from your app menu — or `~/.local/bin/black-and-white`.

- `black-and-white` — fullscreen (gamescope)
- `black-and-white-windowed` — plain windowed fallback

## Expansion: Creature Isle
Got the **Creature Isle** expansion too? Install the base game first, then:
```bash
bash install-creature-isle.sh /path/to/your/CreatureIsle.iso
```
It installs into the same bottle and gets its own launcher (`creature-isle`) that reuses
all the same GPU/fullscreen fixes — so no second graphics fight. Creature Isle has a disc
check; keep your ISO mounted while playing (or apply your own No-CD for the copy you own).

## Why this exists (the hard part it solves)
Old DirectX-7 games like B&W fight modern Linux. The fixes, learned the hard way:

| Symptom | Cause | Fix (done for you) |
|---|---|---|
| Crashes instantly | v1.0 exe misses a DirectInput COM class on Wine | official **1.20** patch |
| Crashes after intro | Bink-video / SafeDisc on modern systems | **1.42** fan patch (also drops the disc check) |
| **See-through land & people** | On hybrid laptops the **dGPU's OpenGL is broken**; Wine renders via OpenGL | force the **integrated GPU** (`__GLX_VENDOR_LIBRARY_NAME=mesa`) |
| Fullscreen breaks the graphics | the game's own fullscreen does a display mode-switch back onto the broken GPU | run it fullscreen **inside gamescope** on the iGPU — virtual display, no mode-switch |

The launchers auto-detect your GPU, so it adapts to AMD/Intel/NVIDIA/hybrid.

## Troubleshooting
- **See-through graphics** → make sure you launch via `black-and-white` (it forces the iGPU).
- **Black screen in gamescope** → it grabbed the wrong GPU; the launcher forces the iGPU via
  `--prefer-vk-device` — check `lspci -nn | grep -i vga`.
- **Won't start / DirectInput error** → the patches didn't apply to a fresh install; re-run
  `install.sh` (it starts from a clean Wine bottle).

## Credits
- The B&W community at **bwgame.net** for the **1.42 fan patch** (the real modern-systems hero).
- The Internet Archive for hosting the official patches.
- **Wine**, **DXVK**, and **gamescope**.

## License
MIT (see `LICENSE`) — applies to the scripts in this repo only, not to the game.
