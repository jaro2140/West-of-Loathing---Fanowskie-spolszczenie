#!/usr/bin/env bash
# Przywraca angielski — Linux / SteamOS.
set -euo pipefail

INSTALLER_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$INSTALLER_DIR/../.." && pwd)"
# shellcheck source=../common/paths.sh
source "$INSTALLER_DIR/../common/paths.sh"

BACKUP="$ROOT/backup"

LINUX_CANDIDATES=(
  "$HOME/.local/share/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.steam/steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.steam/root/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
)

if ! GAME_STREAMING="$(resolve_game_streaming "$ROOT" "${LINUX_CANDIDATES[@]}")"; then
  echo "Nie znaleziono instalacji gry. Ustaw WOL_STREAMING w game-path.env"
  exit 1
fi

if [[ ! -f "$BACKUP/core" && -f "$ROOT/original/StreamingAssets/core" ]]; then
  echo "Brak backup/ — uzywam original/StreamingAssets/"
  BACKUP="$ROOT/original/StreamingAssets"
fi

if [[ ! -f "$BACKUP/core" ]]; then
  echo "Blad: brak backup/core"
  echo "Steam: West of Loathing -> wlasciwosci -> Zweryfikuj pliki"
  exit 1
fi

echo "Przywracanie angielskiego..."
echo "Gra: $GAME_STREAMING"
restore_all_patches "$BACKUP" "$GAME_STREAMING"
echo "Gotowe."
