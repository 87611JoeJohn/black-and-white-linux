#!/usr/bin/env bash
# Black & White (2001) — fullscreen launcher for Linux.
# Auto-detects your GPU setup (AMD / Intel / NVIDIA / hybrid) and does the right thing.
# Part of: github.com/87611JoeJohn/black-and-white-linux
set -u
export WINEPREFIX="${BW_PREFIX:-$HOME/.bw}"
export WINEDEBUG=-all
BW='HKCU\Software\Lionhead Studios Ltd\Black & White\BWSetup'
GAME="$WINEPREFIX/drive_c/Program Files (x86)/Lionhead Studios Ltd/Black & White"

[ -f "$GAME/runblack.exe" ] || { echo "Black & White isn't installed in $WINEPREFIX. Run install.sh first."; exit 1; }
command -v gamescope >/dev/null 2>&1 || { echo "Please install gamescope (your distro's package)."; exit 1; }

# ---- GPU detection ---------------------------------------------------------
gpus="$(lspci -nn 2>/dev/null | grep -iE 'VGA|3D controller|Display controller')"
igpu_id="$(printf '%s\n' "$gpus" | grep -iE 'Intel|AMD|ATI|Radeon' | grep -oiE '(1002|8086):[0-9a-f]{4}' | head -1)"
has_nvidia="$(printf '%s\n' "$gpus" | grep -ci '10de:')"

GS=()                                   # gamescope GPU-select args
if [ -n "$igpu_id" ]; then
  # AMD/Intel integrated GPU present (incl. NVIDIA-hybrid laptops where the dGPU's
  # OpenGL is often broken). Force the game's OpenGL + gamescope onto the iGPU = the fix.
  export __GLX_VENDOR_LIBRARY_NAME=mesa
  GS=(--prefer-vk-device "$igpu_id")
  echo "GPU: using integrated ($igpu_id) for rendering — the reliable path."
elif [ "$has_nvidia" -gt 0 ]; then
  # NVIDIA-only machine: its OpenGL works fine, let it render.
  echo "GPU: NVIDIA-only — using it directly."
else
  echo "GPU: using default."
fi

# ---- game config: fullscreen INSIDE gamescope (no window, no title bar, no mode-switch) ----
for d in ddraw d3dimm d3d11 dxgi d3d8 d3d9; do
  wine reg delete 'HKCU\Software\Wine\DllOverrides' /v "$d" /f >/dev/null 2>&1
done
wine reg delete 'HKCU\Software\Wine\Explorer' /v Desktop /f >/dev/null 2>&1
wine reg add "$BW" /v FullScreen /t REG_DWORD /d 1 /f >/dev/null 2>&1
wine reg add "$BW" /v ScreenW   /t REG_DWORD /d 1920 /f >/dev/null 2>&1
wine reg add "$BW" /v ScreenH   /t REG_DWORD /d 1200 /f >/dev/null 2>&1
wineserver -w

cd "$GAME" || exit 1
exec gamescope "${GS[@]}" -w 1920 -h 1200 -f -- wine runblack.exe "$@"
