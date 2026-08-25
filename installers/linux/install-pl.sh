#!/usr/bin/env bash
# Installs the Polish patch for West of Loathing on Linux/SteamOS.
#
# 1. Finds the Linux/SteamOS game installation (Steam).
# 2. Instaluje tekst (core/house/main_scene w StreamingAssets).
# 3. [EKSPERYMENTALNIE, jesli bundle jest w paczce] Instaluje plugin BepInEx,
#    ktory tlumaczy dodatkowo tekst zaszyty w kodzie gry (Assembly-CSharp.dll)
#    - patrz Docs/DLL_HARDCODED_TEXT.md. Ten krok NIE jest krytyczny: jesli
#    sie nie powiedzie, tekst gry (krok 2) juz dziala niezaleznie od niego.
#
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
OS_LABEL="Linux/SteamOS"
BEPINEX_OS="linux"
GAME_CANDIDATES=(
  "$HOME/.local/share/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.steam/steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.steam/root/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
  "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/West of Loathing/West of Loathing_Data/StreamingAssets"
)

resolve_layout "$ROOT" "$PLATFORM"

if [[ ! -f "$PATCHES/core" ]]; then
  echo "Blad: brak $PATCHES/core"
  echo "Najpierw: python _App/src/pack.py"
  exit 1
fi
verify_patch_platform "$PATCHES" "$PLATFORM"

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
    if EXECUTABLE="$(detect_linux_executable "$GAME_ROOT")"; then
      echo "Wykryty plik wykonywalny: $EXECUTABLE"
    else
      echo ""
      echo "UWAGA: nie udalo sie automatycznie wykryc pliku wykonywalnego gry (diagnostyka wyzej)."
      echo "Sam plugin JEST juz skopiowany — to tylko krok pomocniczy przy uruchamianiu."
      echo "Ustaw WOL_LINUX_EXECUTABLE w game-path.env i uruchom install-pl.sh ponownie,"
      echo "albo uruchom recznie: \"$GAME_ROOT/run_bepinex.sh\" \"<plik wykonywalny gry>\""
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
echo "Weryfikacja: $SCRIPT_DIR/verify-install.sh"
echo "Przywrocenie EN: $SCRIPT_DIR/restore-en.sh"
