#!/usr/bin/env bash
# Instaluje polski patch — macOS (Steam).
set -euo pipefail

INSTALLER_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$INSTALLER_DIR/../.." && pwd)"
# shellcheck source=../common/paths.sh
source "$INSTALLER_DIR/../common/paths.sh"

PATCHES="$ROOT/patches"
BACKUP="$ROOT/backup"

MAC_CANDIDATES=(
  "$HOME/Library/Application Support/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.steam/steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
)

if [[ ! -f "$PATCHES/core" ]]; then
  echo "Blad: brak $PATCHES/core"
  exit 1
fi

if ! GAME_STREAMING="$(resolve_game_streaming "$ROOT" "${MAC_CANDIDATES[@]}")"; then
  echo "Nie znaleziono instalacji gry (Steam na macOS)."
  echo "Skopiuj game-path.env.example jako game-path.env w katalogu projektu."
  exit 1
fi

echo "Gra:   $GAME_STREAMING"
echo "Patch: $PATCHES"
echo ""
mkdir -p "$BACKUP"
print_patch_plan "$PATCHES"
echo ""
echo "Instalacja polskiego patcha..."
install_all_patches "$PATCHES" "$GAME_STREAMING" "$BACKUP"

echo ""
echo "Gotowe."
echo "Weryfikacja: $INSTALLER_DIR/verify-install.sh"
echo "Przywroc EN:  $INSTALLER_DIR/restore-en.sh"
