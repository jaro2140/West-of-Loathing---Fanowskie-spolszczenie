#!/usr/bin/env bash
# Weryfikuje instalacje patcha tekstowego oraz (jesli dotyczy) pluginu
# BepInEx. Jeden skrypt dla Linux/SteamOS i macOS.
#
# Windows: uzyj installers\windows\verify-install.bat zamiast tego skryptu.
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
    OS_LABEL="Linux/SteamOS"
    BEPINEX_OS="linux"
    GAME_CANDIDATES=(
      "$HOME/.local/share/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
      "$HOME/.steam/steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
      "$HOME/.steam/root/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
      "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
    )
    ;;
  Darwin*)
    OS_LABEL="macOS"
    BEPINEX_OS="macos"
    GAME_CANDIDATES=(
      "$HOME/Library/Application Support/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
      "$HOME/.steam/steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
    )
    ;;
  *)
    echo "Ten skrypt obsluguje Linux/SteamOS i macOS."
    echo "Na Windows uruchom: installers\\windows\\verify-install.bat"
    exit 1
    ;;
esac

echo "=== West of Loathing PL — weryfikacja ($OS_LABEL) ==="
echo ""

if [[ ! -f "$PATCHES/core" ]]; then
  echo "BLAD: brak $PATCHES/core — uruchom: python _App/src/pack.py"
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
