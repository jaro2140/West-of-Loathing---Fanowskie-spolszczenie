#!/usr/bin/env bash
# Instaluje polski patch West of Loathing: jeden skrypt, jedno uruchomienie.
#
# 1. Wykrywa system (Linux/SteamOS albo macOS) i instalacje gry (Steam).
# 2. Instaluje tekst (core/house/main_scene w StreamingAssets).
# 3. [EKSPERYMENTALNIE, jesli bundle jest w paczce] Instaluje plugin BepInEx,
#    ktory tlumaczy dodatkowo tekst zaszyty w kodzie gry (Assembly-CSharp.dll)
#    - patrz Docs/DLL_HARDCODED_TEXT.md. Ten krok NIE jest krytyczny: jesli
#    sie nie powiedzie, tekst gry (krok 2) juz dziala niezaleznie od niego.
#
# Windows: uzyj installers\windows\install-pl.bat zamiast tego skryptu.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Wykrycie ukladu: w repo prywatnym ten skrypt siedzi w Installers/, a
# prawdziwy korzen projektu (z Game_Translate/) jest jeden poziom wyzej. W
# paczce release ten skrypt siedzi juz w korzeniu paczki (patches/ obok).
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
    echo "Na Windows uruchom: installers\\windows\\install-pl.bat"
    exit 1
    ;;
esac

if [[ ! -f "$PATCHES/core" ]]; then
  echo "Blad: brak $PATCHES/core"
  echo "Najpierw: python _App/src/pack.py"
  exit 1
fi

if ! GAME_STREAMING="$(resolve_game_streaming "$ROOT" "${GAME_CANDIDATES[@]}")"; then
  echo "Nie znaleziono instalacji gry ($OS_LABEL)."
  echo "Utworz game-path.env w katalogu glownym paczki (wzor: game-path.env.example)"
  exit 1
fi

# Trwaly backup/manifest zwiazany z folderem GRY, nie z paczka instalatora
# (ktora bywa przenoszona/rozpakowywana na nowo — patrz komentarz przy
# resolve_layout() w common/paths.sh). Migrujemy tez ewentualny stary backup
# sprzed tej poprawki, jesli jeszcze lezy obok paczki.
LEGACY_BACKUP="$BACKUP"
BACKUP="$(game_backup_dir "$GAME_STREAMING")"
mkdir -p "$BACKUP"
migrate_legacy_backup "$LEGACY_BACKUP" "$BACKUP"

echo "=== West of Loathing PL — instalacja ($OS_LABEL) ==="
echo "Gra:   $GAME_STREAMING"
echo "Patch: $PATCHES"
echo ""
print_patch_plan "$PATCHES"
echo ""
echo "--- 1/2: tekst gry (patch JSON) ---"
install_all_patches "$PATCHES" "$GAME_STREAMING" "$BACKUP"
echo "Gotowe."

echo ""
echo "--- 2/2: [EKSPERYMENTALNE] plugin BepInEx (tekst zaszyty w kodzie gry) ---"
BEPINEX_BUNDLE="$ROOT/Game_Translate/build/bepinex/$BEPINEX_OS"
[[ -d "$BEPINEX_BUNDLE" ]] || BEPINEX_BUNDLE="$ROOT/bepinex/$BEPINEX_OS"

if [[ ! -d "$BEPINEX_BUNDLE" ]]; then
  echo "Pomijam — ta paczka nie zawiera dodatku BepInEx dla $OS_LABEL."
else
  GAME_ROOT="$(bepinex_game_root "$GAME_STREAMING")"
  if ! ( install_bepinex "$BEPINEX_BUNDLE" "$GAME_ROOT" "$BACKUP" ); then
    echo ""
    echo "UWAGA: instalacja pluginu BepInEx (eksperymentalna) nie powiodla sie — patrz komunikat wyzej."
    echo "Tekst gry (krok 1/2) jest juz zainstalowany i dziala NIEZALEZNIE od tego kroku."
  else
    RUN_HINT="\"$GAME_ROOT/run_bepinex.sh\" %command%"
    if [[ "$OS_NAME" == Linux* ]]; then
      if EXECUTABLE="$(detect_linux_executable "$GAME_ROOT")"; then
        echo "Wykryty plik wykonywalny: $EXECUTABLE"
      else
        echo ""
        echo "UWAGA: nie udalo sie automatycznie wykryc pliku wykonywalnego gry (diagnostyka wyzej)."
        echo "Sam plugin JEST juz skopiowany — to tylko krok pomocniczy przy uruchamianiu."
        echo "Ustaw WOL_LINUX_EXECUTABLE w game-path.env i uruchom ./install-pl.sh ponownie,"
        echo "albo uruchom recznie: \"$GAME_ROOT/run_bepinex.sh\" \"<plik wykonywalny gry>\""
      fi
    fi
    echo ""
    echo "Aby aktywowac plugin przy starcie z poziomu Steam: West of Loathing ->"
    echo "Wlasciwosci -> Opcje uruchamiania, wpisz:"
    echo ""
    echo "  $RUN_HINT"
    echo ""
    echo "Log pluginu po uruchomieniu: $GAME_ROOT/BepInEx/LogOutput.log"
  fi
fi

echo ""
echo "=== Gotowe ==="
echo "Weryfikacja: ./verify-install.sh"
echo "Przywrocenie EN (tekstu i pluginu, jesli zainstalowany): ./restore-en.sh"
