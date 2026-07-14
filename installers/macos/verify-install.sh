#!/usr/bin/env bash
# Weryfikacja instalacji patcha — macOS.
set -euo pipefail

INSTALLER_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$INSTALLER_DIR/../.." && pwd)"
# shellcheck source=../common/paths.sh
source "$INSTALLER_DIR/../common/paths.sh"

PATCHES="$ROOT/patches"

echo "=== West of Loathing — weryfikacja patcha (macOS) ==="
echo ""

if [[ ! -f "$PATCHES/core" ]]; then
  echo "BLAD: brak $PATCHES/core"
  exit 1
fi

echo "Patch:"
echo "  $PATCHES/core ($(file_size "$PATCHES/core") B)"
if has_polish_text "$PATCHES/core"; then
  echo "  tekst PL w patchu: TAK"
else
  echo "  tekst PL w patchu: NIE"
fi
echo ""

MAC_CANDIDATES=(
  "$HOME/Library/Application Support/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.steam/steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
)

FOUND=0
if GAME_STREAMING="$(resolve_game_streaming "$ROOT" "${MAC_CANDIDATES[@]}" 2>/dev/null)"; then
  echo "Gra: $GAME_STREAMING"
  for name in "${PATCH_BUNDLES[@]}"; do
    patch="$PATCHES/$name"
    game="$GAME_STREAMING/$name"
    [[ -f "$patch" ]] || continue
    if [[ -f "$game" ]] && cmp -s "$patch" "$game"; then
      echo "  $name: ZAINSTALOWANY ($(file_size "$game") B)"
    elif [[ -f "$game" ]]; then
      echo "  $name: NIE zainstalowany"
      echo "    patches: $(file_size "$patch") B | gra: $(file_size "$game") B"
    else
      echo "  $name: brak pliku w grze"
    fi
  done
  echo ""
fi

for dir in "${MAC_CANDIDATES[@]}"; do
  [[ -d "$dir" ]] || continue
  FOUND=1
  core="$dir/core"
  echo "--- $dir ---"
  if [[ ! -f "$core" ]]; then
    echo "  brak core"
    continue
  fi
  if cmp -s "$PATCHES/core" "$core" 2>/dev/null; then
    echo "  status: ZAINSTALOWANY (identyczny z patch)"
  else
    echo "  status: NIE zainstalowany (rozni sie)"
  fi
  if has_polish_text "$core"; then
    echo "  tekst PL: TAK"
  else
    echo "  tekst PL: NIE"
  fi
  echo ""
done

if [[ "$FOUND" -eq 0 ]]; then
  echo "Nie znaleziono gry. Ustaw game-path.env"
  exit 1
fi
