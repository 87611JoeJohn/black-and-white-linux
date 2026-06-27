#!/usr/bin/env bash
# Black & White: Creature Isle (2002) — fullscreen launcher for Linux.
# Reuses the same GPU/fullscreen fixes as the base game. Install B&W first, then
# install-creature-isle.sh. Auto-detects AMD / Intel / NVIDIA / hybrid.
set -u
export WINEPREFIX="${BW_PREFIX:-$HOME/.bw}"
export WINEDEBUG=-all
BW='HKCU\Software\Lionhead Studios Ltd\Black & White\BWSetup'
CI="$WINEPREFIX/drive_c/Program Files (x86)/Lionhead Studios Ltd/Black & White/CreatureIsle"

[ -f "$CI/CreatureIsle.exe" ] || { echo "Creature Isle isn't installed. Run install-creature-isle.sh."; exit 1; }
command -v gamescope >/dev/null 2>&1 || { echo "Please install gamescope."; exit 1; }

# integrated GPU (AMD/Intel) for rendering — the fix for see-through on hybrid laptops
igpu="$(lspci -nn 2>/dev/null | grep -iE 'VGA|3D controller|Display controller' \
        | grep -iE 'Intel|AMD|ATI|Radeon' | grep -oiE '(1002|8086):[0-9a-f]{4}' | head -1)"
GS=(); [ -n "$igpu" ] && { export __GLX_VENDOR_LIBRARY_NAME=mesa; GS=(--prefer-vk-device "$igpu"); }

for d in ddraw d3dimm d3d11 dxgi d3d8 d3d9; do
  wine reg delete 'HKCU\Software\Wine\DllOverrides' /v "$d" /f >/dev/null 2>&1
done
wine reg delete 'HKCU\Software\Wine\Explorer' /v Desktop /f >/dev/null 2>&1
wine reg add "$BW" /v FullScreen /t REG_DWORD /d 1 /f >/dev/null 2>&1
wine reg add "$BW" /v ScreenW /t REG_DWORD /d 1920 /f >/dev/null 2>&1
wine reg add "$BW" /v ScreenH /t REG_DWORD /d 1200 /f >/dev/null 2>&1
wineserver -w

cd "$CI" || exit 1
exec gamescope "${GS[@]}" -w 1920 -h 1200 -f -- wine CreatureIsle.exe "$@"
