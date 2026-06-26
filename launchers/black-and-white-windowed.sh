#!/usr/bin/env bash
# Black & White (2001) — plain windowed launcher (fallback if gamescope isn't available).
# Auto-detects the GPU and forces the integrated one on hybrid laptops.
set -u
export WINEPREFIX="${BW_PREFIX:-$HOME/.bw}"
export WINEDEBUG=-all
BW='HKCU\Software\Lionhead Studios Ltd\Black & White\BWSetup'
GAME="$WINEPREFIX/drive_c/Program Files (x86)/Lionhead Studios Ltd/Black & White"

[ -f "$GAME/runblack.exe" ] || { echo "Black & White isn't installed in $WINEPREFIX. Run install.sh first."; exit 1; }

# force the integrated GPU's OpenGL on AMD/Intel/hybrid systems (the fix for see-through)
if lspci -nn 2>/dev/null | grep -iE 'VGA|3D controller|Display controller' \
     | grep -iqE 'Intel|AMD|ATI|Radeon'; then
  export __GLX_VENDOR_LIBRARY_NAME=mesa
fi

for d in ddraw d3dimm d3d11 dxgi d3d8 d3d9; do
  wine reg delete 'HKCU\Software\Wine\DllOverrides' /v "$d" /f >/dev/null 2>&1
done
wine reg delete 'HKCU\Software\Wine\Explorer' /v Desktop /f >/dev/null 2>&1
wine reg add "$BW" /v FullScreen /t REG_DWORD /d 0 /f >/dev/null 2>&1
wine reg add "$BW" /v ScreenW   /t REG_DWORD /d 1920 /f >/dev/null 2>&1
wine reg add "$BW" /v ScreenH   /t REG_DWORD /d 1200 /f >/dev/null 2>&1
wineserver -w

cd "$GAME" || exit 1
exec wine runblack.exe "$@"
