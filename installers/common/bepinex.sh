# Wspolna logika instalatora BepInEx+Harmony (plugin z tekstem UI zaszytym w
# Assembly-CSharp.dll - patrz Docs/DLL_HARDCODED_TEXT.md). Osobna od paths.sh
# (patch JSON w StreamingAssets), bo model jest inny: BepInEx DODAJE nowe
# pliki/foldery obok gry zamiast nadpisywac istniejace, wiec "cofniecie" to
# usuniecie dokladnie tego, co zostalo dodane (manifest), a nie przywrocenie
# kopii zapasowej pojedynczego pliku.
#
# Uzycie: source "$(dirname "$0")/../common/bepinex.sh"

# Z folderu StreamingAssets wyprowadza root gry (dwa poziomy wyzej: usuwa
# "/<Nazwa>_Data/StreamingAssets"), czyli miejsce obok pliku wykonywalnego /
# paczki .app, gdzie instaluje sie BepInEx.
bepinex_game_root() {
  local game_streaming="$1"
  dirname "$(dirname "$game_streaming")"
}

# Buduje liste wszystkich plikow (sciezki wzgledne) w katalogu bundle.
_bepinex_list_files() {
  local bundle="$1"
  (cd "$bundle" && find . -type f | sed 's#^\./##') | sort
}

# Instaluje bundle BepInEx do game_root. Zapisuje manifest (liste dodanych
# plikow wzglednych) w backup/bepinex_manifest.txt - to jest "punkt zwrotny":
# restore_bepinex czyta dokladnie ten manifest i usuwa dokladnie te pliki,
# nic wiecej. Bezpieczne do wielokrotnego uruchomienia (aktualizacja pluginu):
# jesli manifest juz istnieje, dopisuje/aktualizuje pliki bez ich duplikowania.
# Jesli w game_root jest juz folder BepInEx/ ALE bez naszego manifestu (ktos
# inny go tam postawil recznie / inny mod), przerywa - nie chcemy nadpisywac
# ani "przejmowac na wlasnosc" cudzej instalacji BepInEx bez pytania.
install_bepinex() {
  local bundle="$1"
  local game_root="$2"
  local backup="$3"

  if [[ ! -d "$bundle" ]]; then
    echo "  blad: brak bundle $bundle — najpierw: _App/src/prepare-bepinex-bundle.sh"
    exit 1
  fi

  local manifest="$backup/bepinex_manifest.txt"
  mkdir -p "$backup"

  if [[ -d "$game_root/BepInEx" && ! -f "$manifest" ]]; then
    if [[ -f "$game_root/BepInEx/plugins/WestOfLoathingPL.dll" ]]; then
      # Nasz plugin juz tam jest, ale manifest zgubiony - typowy skutek
      # przeniesienia/rozpakowania paczki instalatora na nowo miedzy
      # uruchomieniami (manifest dawniej byl liczony wzgledem paczki, nie
      # gry - patrz resolve_layout() w paths.sh). Odzyskujemy: skoro to NASZ
      # plugin, odtwarzamy manifest z listy plikow bundle'a zamiast przerywac.
      echo "  wykryto $game_root/BepInEx z naszym pluginem (WestOfLoathingPL.dll),"
      echo "  ale bez manifestu w $backup — typowe po przeniesieniu paczki."
      echo "  Odtwarzam manifest zamiast przerywac..."
      _bepinex_list_files "$bundle" > "$manifest"
    else
      echo "  blad: $game_root/BepInEx juz istnieje, a nie zostal zainstalowany przez"
      echo "        ten skrypt (brak $manifest i brak naszego pluginu w BepInEx/plugins/)."
      echo "        Przerywam, zeby nie nadpisac cudzej instalacji BepInEx/innych"
      echo "        pluginow. Usun recznie albo dopisz obsluge, jesli to zamierzone."
      exit 1
    fi
  fi

  echo "  cel: $game_root"
  local files
  files="$(_bepinex_list_files "$bundle")"

  local rel src dst count=0
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    src="$bundle/$rel"
    dst="$game_root/$rel"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    count=$((count + 1))
  done <<< "$files"

  # manifest = suma poprzednich wpisow + nowych (unikalne, posortowane) -
  # bezpieczne przy ponownym uruchomieniu / aktualizacji.
  if [[ -f "$manifest" ]]; then
    cat "$manifest" <(echo "$files") | sort -u > "$manifest.tmp"
    mv "$manifest.tmp" "$manifest"
  else
    echo "$files" > "$manifest"
  fi

  # uprawnienia wykonywalne dla skryptu startowego macOS/Linux
  [[ -f "$game_root/run_bepinex.sh" ]] && chmod +x "$game_root/run_bepinex.sh"

  echo "  skopiowano: $count plikow"
  echo "  manifest (punkt zwrotny): $manifest"
}

# Usuwa dokladnie te pliki, ktore install_bepinex zapisal w manifescie, a
# potem probuje posprzatac puste katalogi (BepInEx/plugins, BepInEx/core,
# BepInEx) - tylko jesli sa faktycznie puste, zeby nie usunac czegos, co
# gracz dolozyl recznie (np. inny plugin) po naszej instalacji.
restore_bepinex() {
  local game_root="$1"
  local backup="$2"

  local manifest="$backup/bepinex_manifest.txt"
  if [[ ! -f "$manifest" ]]; then
    echo "  brak $manifest — BepInEx nie byl instalowany tym skryptem, nic do cofniecia."
    return 0
  fi

  local rel removed=0 kept=0
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    if [[ -f "$game_root/$rel" ]]; then
      rm -f "$game_root/$rel"
      removed=$((removed + 1))
    else
      kept=$((kept + 1))
    fi
  done < "$manifest"

  # posprzataj puste katalogi, od najglebszych
  find "$game_root/BepInEx" -depth -type d -empty -delete 2>/dev/null || true

  rm -f "$manifest"
  echo "  usunieto: $removed plikow (juz brakowalo: $kept)"
  echo "  BepInEx cofniety."
}

# Sprawdza magic bytes ELF (0x7F 'E' 'L' 'F') zamiast polegac na bicie +x -
# niektore systemy plikow (np. exFAT na kartach SD Steam Decka, czeste
# miejsce instalacji gier) nie zachowuja uprawnien Unixowych poprawnie, wiec
# "find -perm -u+x" potrafi nie znalezc niczego mimo ze plik jest prawdziwym
# wykonywalnym binarium gry.
_is_elf_binary() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  local magic
  magic="$(head -c4 "$f" 2>/dev/null | od -An -tx1 2>/dev/null | tr -d ' \n')"
  [[ "$magic" == "7f454c46" ]]
}

# Znajduje glowny plik wykonywalny gry Unity w game_root (potrzebny do
# uruchomienia przez run_bepinex.sh). Kolejnosc: WOL_LINUX_EXECUTABLE (env/
# game-path.env) -> "<GameRoot>/<prefiks _Data>" (standardowy uklad buildu
# Unity) -> jedyny plik ELF w katalogu glownym po odfiltrowaniu znanych
# "nie-launcherow" (UnityCrashHandler, skrypty .sh/.py/.so ktore BepInEx/gra
# rowniez tam stawia). Na niepowodzenie wypisuje na stderr pelna diagnostyke
# (co widzial, co odrzucil i dlaczego), zeby user mial z czym pracowac zamiast
# golego "nie znaleziono".
detect_linux_executable() {
  local game_root="$1"

  if [[ -n "${WOL_LINUX_EXECUTABLE:-}" ]]; then
    echo "$WOL_LINUX_EXECUTABLE"
    return 0
  fi

  local data_dir
  data_dir="$(find "$game_root" -maxdepth 1 -type d -iname "*_Data" | head -1)"
  if [[ -n "$data_dir" ]]; then
    local expected="$game_root/$(basename "${data_dir%_Data}")"
    if _is_elf_binary "$expected"; then
      echo "$expected"
      return 0
    fi
  fi

  local candidates=() rejected=()
  local f base
  while IFS= read -r f; do
    base="$(basename "$f")"
    case "$base" in
      *.sh|*.so|*.py|*.txt|*.md|*.json|*.pdb|UnityCrashHandler*|run_bepinex.sh)
        rejected+=("$base  (odfiltrowane po nazwie)")
        continue
        ;;
    esac
    if _is_elf_binary "$f"; then
      candidates+=("$f")
    else
      rejected+=("$base  (nie jest binarium ELF)")
    fi
  done < <(find "$game_root" -maxdepth 1 -type f)

  if [[ ${#candidates[@]} -eq 1 ]]; then
    echo "${candidates[0]}"
    return 0
  fi

  {
    echo "Diagnostyka wykrywania pliku wykonywalnego w: $game_root"
    if [[ ${#candidates[@]} -gt 1 ]]; then
      echo "Znaleziono WIECEJ NIZ JEDEN mozliwy plik wykonywalny (niejednoznaczne):"
      printf '  - %s\n' "${candidates[@]}"
    else
      echo "Nie znaleziono zadnego pliku wygladajacego na binarium gry (ELF)."
    fi
    if [[ ${#rejected[@]} -gt 0 ]]; then
      echo "Odrzucone kandydaty:"
      printf '  - %s\n' "${rejected[@]}"
    fi
    echo "Napraw recznie: ustaw WOL_LINUX_EXECUTABLE=/pelna/sciezka/do/pliku w game-path.env"
  } >&2

  return 1
}

bepinex_status() {
  local game_root="$1"
  local backup="$2"
  local manifest="$backup/bepinex_manifest.txt"

  if [[ -f "$manifest" ]]; then
    echo "  BepInEx zainstalowany tym skryptem w: $game_root ($(wc -l < "$manifest" | tr -d ' ') plikow, manifest: $manifest)"
  elif [[ -d "$game_root/BepInEx" ]]; then
    echo "  W $game_root jest folder BepInEx/, ale NIE zostal zainstalowany tym skryptem (brak manifestu)."
  else
    echo "  BepInEx nie jest zainstalowany w $game_root."
  fi
}
