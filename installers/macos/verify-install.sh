#!/usr/bin/env bash
# Verifies text files and BepInEx installed by the macOS installer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLERS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$INSTALLERS_DIR/.." && pwd)"
# shellcheck source=common/paths.sh
source "$INSTALLERS_DIR/common/paths.sh"
# shellcheck source=common/bepinex.sh
source "$INSTALLERS_DIR/common/bepinex.sh"

OS_NAME="$(uname -s 2>/dev/null || echo Unknown)"
if [[ "$OS_NAME" != Darwin* ]]; then
  echo "Ten instalator jest przeznaczony dla macOS."
  exit 1
fi

PLATFORM="macos"
OS_LABEL="macOS"
BEPINEX_OS="macos"
GAME_CANDIDATES=(
  "$HOME/Library/Application Support/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.steam/steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
)

resolve_layout "$ROOT" "$PLATFORM"

echo "=== West of Loathing PL — weryfikacja ($OS_LABEL) ==="
echo ""

if [[ ! -f "$PATCHES/core" ]]; then
  echo "BLAD: brak $PATCHES/core — uruchom: python _App/src/pack.py"
  exit 1
fi
verify_patch_platform "$PATCHES" "$PLATFORM"

echo "Patch:"
echo "  $PATCHES/core ($(file_size "$PATCHES/core") B)"
if has_polish_text "$PATCHES/core"; then
  echo "  tekst PL w patchu: TAK"
else
  echo "  tekst PL w patchu: NIE"
fi
echo ""

FOUND=0
if GAME_STREAMING="$(resolve_game_streaming "$ROOT" "${GAME_CANDIDATES[@]}" 2>/dev/null)"; then
  FOUND=1
  echo "Gra: $GAME_STREAMING"
  for name in "${PATCH_BUNDLES[@]}"; do
    patch="$PATCHES/$name"
    game="$GAME_STREAMING/$name"
    [[ -f "$patch" ]] || continue
    if [[ -f "$game" ]] && cmp -s "$patch" "$game"; then
      echo "  $name: ZAINSTALOWANY ($(file_size "$game") B)"
    elif [[ -f "$game" ]]; then
      echo "  $name: NIE zainstalowany (gra ma inny plik niz patches/)"
      echo "    patches: $(file_size "$patch") B | gra: $(file_size "$game") B"
    else
      echo "  $name: brak pliku w grze"
    fi
  done

  echo ""
  echo "Plugin BepInEx (eksperymentalny):"
  GAME_ROOT="$(bepinex_game_root "$GAME_STREAMING")"
  bepinex_status "$GAME_ROOT" "$(game_backup_dir "$GAME_STREAMING")"
else
  echo "Nie znaleziono gry. Ustaw game-path.env (WOL_STREAMING=...)"
fi

echo ""
if [[ "$FOUND" -eq 0 ]]; then
  exit 1
fi

echo "Menu graficzne: python _App/src/verify-ui-patch.py"
