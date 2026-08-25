#!/usr/bin/env bash
# Restores the original English files on Linux/SteamOS and removes the plugin.
# Restores text files and BepInEx installed by the Linux installer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLERS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$INSTALLERS_DIR/.." && pwd)"
# shellcheck source=common/paths.sh
source "$INSTALLERS_DIR/common/paths.sh"
# shellcheck source=common/bepinex.sh
source "$INSTALLERS_DIR/common/bepinex.sh"

OS_NAME="$(uname -s 2>/dev/null || echo Unknown)"
if [[ "$OS_NAME" != Linux* ]]; then
  echo "Ten instalator jest przeznaczony dla Linux/SteamOS."
  exit 1
fi

PLATFORM="linux"
GAME_CANDIDATES=(
  "$HOME/.local/share/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.steam/steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.steam/root/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
)

resolve_layout "$ROOT" "$PLATFORM"

if ! GAME_STREAMING="$(resolve_game_streaming "$ROOT" "${GAME_CANDIDATES[@]}")"; then
  echo "Nie znaleziono instalacji gry. Ustaw WOL_STREAMING w game-path.env"
  exit 1
fi

# Trwaly backup/manifest zwiazany z folderem GRY, nie z paczka instalatora —
# patrz komentarz przy resolve_layout() w common/paths.sh.
LEGACY_BACKUP="$BACKUP"
BACKUP="$(game_backup_dir "$GAME_STREAMING")"
migrate_legacy_backup "$LEGACY_BACKUP" "$BACKUP"

if [[ ! -f "$BACKUP/core" && -f "$ORIGINAL_STREAMING/core" ]]; then
  echo "Brak backup/ — uzywam oryginalnej kopii gry"
  BACKUP="$ORIGINAL_STREAMING"
fi

if [[ ! -f "$BACKUP/core" ]]; then
  echo "Blad: brak backup/core"
  echo "Steam: West of Loathing -> Wlasciwosci -> Zweryfikuj pliki"
  exit 1
fi

echo "Gra: $GAME_STREAMING"
echo "Przywracanie angielskiego tekstu..."
restore_all_patches "$BACKUP" "$GAME_STREAMING"
echo "Tekst: przywrocono."

GAME_ROOT="$(bepinex_game_root "$GAME_STREAMING")"
if [[ -f "$BACKUP/bepinex_manifest.txt" ]]; then
  echo ""
  echo "Wykryto zainstalowany plugin BepInEx — cofam rowniez..."
  restore_bepinex "$GAME_ROOT" "$BACKUP"
fi

echo ""
echo "Gotowe."
