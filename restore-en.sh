#!/usr/bin/env bash
# Przywraca oryginalny (EN) patch tekstowy oraz — jesli byl zainstalowany —
# cofa plugin BepInEx. Jeden skrypt dla Linux/SteamOS i macOS.
#
# Windows: uzyj installers\windows\restore-en.bat zamiast tego skryptu.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -d "$SCRIPT_DIR/../Game_Translate" ]]; then
  ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
  ROOT="$SCRIPT_DIR"
fi

INSTALLERS_DIR="$ROOT/installers"
[[ -d "$INSTALLERS_DIR" ]] || INSTALLERS_DIR="$ROOT/Installers"
# shellcheck source=common/paths.sh
source "$INSTALLERS_DIR/common/paths.sh"
# shellcheck source=common/bepinex.sh
source "$INSTALLERS_DIR/common/bepinex.sh"

resolve_layout "$ROOT"

OS_NAME="$(uname -s 2>/dev/null || echo Unknown)"
case "$OS_NAME" in
  Linux*)
    GAME_CANDIDATES=(
      "$HOME/.local/share/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
      "$HOME/.steam/steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
      "$HOME/.steam/root/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
      "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
    )
    ;;
  Darwin*)
    GAME_CANDIDATES=(
      "$HOME/Library/Application Support/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
      "$HOME/.steam/steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
    )
    ;;
  *)
    echo "Ten skrypt obsluguje Linux/SteamOS i macOS."
    echo "Na Windows uruchom: installers\\windows\\restore-en.bat"
    exit 1
    ;;
esac

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
