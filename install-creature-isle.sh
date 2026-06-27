#!/usr/bin/env bash
# =============================================================================
#  Black & White: Creature Isle (2002) — Linux installer (the expansion)
#  Run AFTER install.sh (it needs Black & White already installed in the bottle).
#  You provide YOUR OWN Creature Isle disc/ISO.
#  Usage:  bash install-creature-isle.sh /path/to/CreatureIsle.iso
# =============================================================================
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${BW_PREFIX:-$HOME/.bw}"
BWDIR="$PREFIX/drive_c/Program Files (x86)/Lionhead Studios Ltd/Black & White"
WORK="$HERE/work-ci"; mkdir -p "$WORK"
say(){ echo; echo "── $* ────────────────────────────"; }
die(){ echo "ERROR: $*" >&2; exit 1; }

[ -f "$BWDIR/runblack.exe" ] || die "Black & White isn't installed yet — run install.sh first."

ISO="${1:-}"
[ -z "$ISO" ] && { read -rp "Path to your Creature Isle disc image (.iso) or folder: " ISO; }
[ -e "$ISO" ] || die "Not found: $ISO"

say "1/3  Reading the Creature Isle disc"
rm -rf "$WORK/disc"; mkdir -p "$WORK/disc"
if [ -d "$ISO" ]; then
  cp -r "$ISO"/. "$WORK/disc"/
elif bsdtar -tf "$ISO" >/dev/null 2>&1 && [ "$(bsdtar -tf "$ISO" 2>/dev/null | wc -l)" -gt 0 ]; then
  bsdtar -xf "$ISO" -C "$WORK/disc"
else
  # some CI ISOs don't read with bsdtar — loop-mount and copy
  L="$(udisksctl loop-setup -f "$ISO" 2>/dev/null | grep -oE '/dev/loop[0-9]+')"; sleep 2
  udisksctl mount -b "$L" >/dev/null 2>&1; MP="$(findmnt -rno TARGET "$L" | head -1)"
  [ -n "$MP" ] || die "Could not read the ISO. Mount it manually and pass the folder."
  cp -r "$MP"/. "$WORK/disc"/; udisksctl unmount -b "$L" >/dev/null 2>&1; udisksctl loop-delete -b "$L" >/dev/null 2>&1
fi
SETUP="$(find "$WORK/disc" -maxdepth 2 -iname 'Setup.exe' | head -1)"
[ -n "$SETUP" ] || die "Setup.exe not found on the Creature Isle disc"

say "2/3  Installing (a setup window opens — click through it; enter your CI key if asked)"
WINEPREFIX="$PREFIX" WINEDEBUG=-all __GLX_VENDOR_LIBRARY_NAME=mesa wine "$SETUP"
CIEXE="$BWDIR/CreatureIsle/CreatureIsle.exe"
[ -f "$CIEXE" ] || die "Creature Isle install not found — did Setup finish?"

say "3/3  Launcher + desktop icon"
install -Dm755 "$HERE/launchers/creature-isle.sh" "$HOME/.local/bin/creature-isle"
ICON="$(find "$BWDIR/CreatureIsle" -maxdepth 1 -iname '*.ico' | head -1)"
[ -z "$ICON" ] && ICON="$HOME/.local/share/icons/black-and-white.ico"
mkdir -p "$HOME/.local/share/icons" "$HOME/.local/share/applications"
[ -f "$ICON" ] && cp -f "$ICON" "$HOME/.local/share/icons/creature-isle.ico"
cat > "$HOME/.local/share/applications/creature-isle.desktop" <<DESK
[Desktop Entry]
Name=Black & White: Creature Isle
Comment=Lionhead Studios / EA (2002)
Exec=$HOME/.local/bin/creature-isle
Icon=$HOME/.local/share/icons/creature-isle.ico
Type=Application
Categories=Game;
Terminal=false
DESK
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null
rm -rf "$WORK"

say "DONE!  Play it from your app menu, or:  ~/.local/bin/creature-isle"
echo "Note: Creature Isle has a disc check. If it asks for the disc, keep your ISO"
echo "mounted while playing (or apply your own No-CD for the copy you own)."
