#!/usr/bin/env bash
# =============================================================================
#  Black & White (2001) — Linux installer
#  github.com/87611JoeJohn/black-and-white-linux
#
#  You provide YOUR OWN game disc/ISO + serial key (the game you legally own).
#  This script installs Wine + gamescope, sets up the bottle, applies the
#  community patches, fixes the graphics, and gives you a fullscreen launcher.
#
#  Usage:   bash install.sh /path/to/your/BlackAndWhite.iso
#           (or run with no argument and it'll ask)
# =============================================================================
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${BW_PREFIX:-$HOME/.bw}"
DIR="$PREFIX/drive_c/Program Files (x86)/Lionhead Studios Ltd/Black & White"
WORK="$HERE/work"; mkdir -p "$WORK"

say(){ echo; echo "── $* ────────────────────────────"; }
die(){ echo "ERROR: $*" >&2; exit 1; }

# ---- 0) your game disc -------------------------------------------------------
ISO="${1:-}"
if [ -z "$ISO" ]; then
  echo "Path to your Black & White disc image (.iso) or extracted disc folder:"
  read -rp "  > " ISO
fi
[ -e "$ISO" ] || die "Not found: $ISO"

# ---- 1) dependencies (Arch / CachyOS) ---------------------------------------
say "1/6  Dependencies"
if command -v pacman >/dev/null 2>&1; then
  sudo pacman -S --needed wine winetricks gamescope wmctrl cabextract unzip curl \
    lib32-vulkan-icd-loader vulkan-icd-loader lib32-mesa \
    vulkan-radeon lib32-vulkan-radeon vulkan-intel lib32-vulkan-intel || die "pacman failed"
else
  echo "Non-Arch distro: install these yourself, then re-run:"
  echo "  wine, winetricks, gamescope, wmctrl, cabextract, curl, unzip,"
  echo "  32-bit Vulkan loader + Mesa drivers (vulkan-radeon/vulkan-intel + lib32)."
  read -rp "  Press Enter once they're installed... " _
fi

# ---- 2) get the disc files ready --------------------------------------------
say "2/6  Reading the disc"
rm -rf "$WORK/disc"; mkdir -p "$WORK/disc"
if [ -d "$ISO" ]; then cp -r "$ISO"/* "$WORK/disc"/; else bsdtar -xf "$ISO" -C "$WORK/disc"; fi
SETUP="$(find "$WORK/disc" -maxdepth 2 -iname 'Setup.exe' | head -1)"
[ -n "$SETUP" ] || die "Setup.exe not found on the disc"

# ---- 3) download the community patches ---------------------------------------
say "3/6  Downloading patches (official 1.20 + 1.42 fan patch)"
curl -fL --retry 2 -o "$WORK/patch120.exe" \
  "https://archive.org/download/black-white-patch-v-1-20/Black_White_Patch_v1_20.exe" || die "1.20 download failed"
curl -fL --retry 2 -A "Mozilla/5.0" -o "$WORK/fanpatch.exe" \
  "https://forum.bwgame.net/downloads/black-white-unofficial-patch-v1-42.1418/download" || die "fan patch download failed"

# ---- 4) Wine bottle + install (GUI) -----------------------------------------
say "4/6  Wine bottle + game install"
rm -rf "$PREFIX"
WINEPREFIX="$PREFIX" WINEDLLOVERRIDES="mscoree=d;mshtml=d" WINEDEBUG=-all wineboot -i
WINEPREFIX="$PREFIX" wineserver -w
echo "  >>> An installer window opens. Full install. Enter YOUR serial key."
echo "      Skip DirectX and online registration at the end. <<<"
WINEPREFIX="$PREFIX" WINEDEBUG=-all wine "$SETUP"
[ -f "$DIR/runblack.exe" ] || die "Game install not found — did Setup finish?"

# ---- 5) patches: 1.20 then 1.42 (de-SafeDiscs; click through both) ----------
say "5/6  Patching (click Next/Yes through each)"
WINEPREFIX="$PREFIX" WINEDEBUG=-all wine "$WORK/patch120.exe"
WINEPREFIX="$PREFIX" WINEDEBUG=-all wine "$WORK/fanpatch.exe"

# ---- 6) launchers + desktop icon --------------------------------------------
say "6/6  Launchers + desktop icon"
install -Dm755 "$HERE/launchers/black-and-white.sh"          "$HOME/.local/bin/black-and-white"
install -Dm755 "$HERE/launchers/black-and-white-windowed.sh" "$HOME/.local/bin/black-and-white-windowed"
ICON="$DIR/white.ICO"; [ -f "$ICON" ] || ICON="$DIR/black.ICO"
mkdir -p "$HOME/.local/share/icons" "$HOME/.local/share/applications"
[ -f "$ICON" ] && cp -f "$ICON" "$HOME/.local/share/icons/black-and-white.ico"
cat > "$HOME/.local/share/applications/black-and-white.desktop" <<DESK
[Desktop Entry]
Name=Black & White
Comment=Lionhead Studios / EA (2001)
Exec=$HOME/.local/bin/black-and-white
Icon=$HOME/.local/share/icons/black-and-white.ico
Type=Application
Categories=Game;
Terminal=false
DESK
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null
rm -rf "$WORK"

say "DONE!  Play it from your app menu, or:  ~/.local/bin/black-and-white"
echo "See-through graphics? The launcher already forces the integrated GPU (the fix)."
