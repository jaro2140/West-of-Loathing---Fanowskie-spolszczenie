# Wspolna logika instalatorow (bash).
# Uzycie: source "$(dirname "$0")/../common/paths.sh"

# Kolejnosc instalacji bundle (core, house, main_scene)
PATCH_BUNDLES=(core house main_scene)

# Wykrywa uklad katalogow: repo prywatne (Game_Translate/build/) albo paczka
# release dla gracza (patches/ obok instalatorow). Ustawia PATCHES, BACKUP
# i ORIGINAL_STREAMING.
#
# UWAGA: BACKUP ustawiony tutaj jest tylko WARTOSCIA DOMYSLNA/dziedziczona,
# liczona wzgledem lokalizacji SKRYPTU/paczki instalatora. To nie jest
# docelowe miejsce na trwaly stan instalacji (manifest BepInEx, kopie
# oryginalnych plikow) - paczka bywa przenoszona na inny nosnik albo
# rozpakowywana na nowo przy kazdej probie (Steam Deck, pendrive), wiec
# cokolwiek zapisane obok NIEJ ginie miedzy uruchomieniami, mimo ze gra i
# ewentualny juz zainstalowany BepInEx zostaja na miejscu. Po ustaleniu
# $GAME_STREAMING kazdy skrypt MUSI nadpisac BACKUP wynikiem
# game_backup_dir(), zeby zwiazac trwaly stan z folderem GRY (stalym), a nie
# z folderem, z ktorego akurat uruchomiono instalator.
resolve_layout() {
  local root="$1"
  if [[ -d "$root/Game_Translate/build/patches" ]]; then
    PATCHES="$root/Game_Translate/build/patches"
    BACKUP="$root/Game_Translate/build/backup"
    ORIGINAL_STREAMING="$root/Game/original/StreamingAssets"
  else
    PATCHES="$root/patches"
    BACKUP="$root/backup"
    ORIGINAL_STREAMING="$root/original/StreamingAssets"
  fi
}

# Trwaly katalog na backup/manifest, zwiazany z folderem GRY (dwa poziomy
# wyzej od StreamingAssets), a nie z lokalizacja skryptu instalatora - patrz
# uwaga przy resolve_layout(). Ukryty folder obok samej gry, wiec przetrwa
# przeniesienie/rozpakowanie paczki instalatora na nowo.
game_backup_dir() {
  local game_streaming="$1"
  echo "$(dirname "$(dirname "$game_streaming")")/.wol_pl_backup"
}

# Jednorazowa migracja z legacy BACKUP (zwiazanego z paczka) do nowego,
# trwalego backup/manifest (zwiazanego z gra) - dla instalacji zrobionych
# przed tym poprawka. Nie nadpisuje niczego, co juz jest w nowym miejscu.
migrate_legacy_backup() {
  local legacy="$1"
  local target="$2"
  [[ -d "$legacy" ]] || return 0
  [[ "$legacy" == "$target" ]] && return 0
  mkdir -p "$target"
  local f base
  for f in "$legacy"/*; do
    [[ -e "$f" ]] || continue
    base="$(basename "$f")"
    if [[ ! -e "$target/$base" ]]; then
      cp -R "$f" "$target/$base"
      echo "  (migracja starego backupu: $base)"
    fi
  done
}

resolve_game_streaming() {
  local root="$1"
  shift
  local candidates=("$@")

  if [[ -n "${WOL_STREAMING:-}" ]]; then
    echo "$WOL_STREAMING"
    return 0
  fi

  local env_file="$root/game-path.env"
  if [[ -f "$env_file" ]]; then
    # shellcheck source=/dev/null
    source "$env_file"
    if [[ -n "${WOL_STREAMING:-}" ]]; then
      echo "$WOL_STREAMING"
      return 0
    fi
  fi

  for path in "${candidates[@]}"; do
    if [[ -d "$path" ]]; then
      echo "$path"
      return 0
    fi
  done
  return 1
}

install_bundle() {
  local name="$1"
  local patches="$2"
  local game_streaming="$3"
  local backup="$4"

  local patch="$patches/$name"
  local target="$game_streaming/$name"
  local bak="$backup/$name"

  if [[ ! -f "$patch" ]]; then
    echo "  pomijam $name (brak patches/$name — uruchom: python scripts/pack.py)"
    return 0
  fi
  if [[ ! -f "$target" ]]; then
    echo "  blad: brak oryginalu $target"
    exit 1
  fi
  if [[ ! -f "$bak" ]]; then
    if [[ "$name" == "core" ]] && has_polish_text "$target"; then
      echo "  UWAGA: brak backupu $name, a plik w grze wyglada na juz spatchowany (PL)."
      echo "         Zapisuje go jako backup mimo to, ale MOZE NIE byc prawdziwym"
      echo "         oryginalem EN. W razie watpliwosci zweryfikuj pliki gry w Steam"
      echo "         (Wlasciwosci -> Zainstalowane pliki) przed instalacja."
    fi
    cp "$target" "$bak"
    echo "  backup: $name ($(file_size "$bak") B)"
  fi
  cp "$patch" "$target"
  echo "  zainstalowano: $name ($(file_size "$target") B)"
}

verify_bundle() {
  local name="$1"
  local patches="$2"
  local game_streaming="$3"

  if cmp -s "$patches/$name" "$game_streaming/$name" 2>/dev/null; then
    echo "  weryfikacja $name: OK"
  else
    echo "  UWAGA: $name rozni sie po kopiowaniu"
  fi
}

restore_bundle() {
  local name="$1"
  local backup="$2"
  local game_streaming="$3"

  local bak="$backup/$name"
  local target="$game_streaming/$name"
  if [[ -f "$bak" ]]; then
    cp "$bak" "$target"
    echo "  przywrocono: $name"
  fi
}

file_size() {
  local f="$1"
  if stat -c%s "$f" 2>/dev/null; then
    return
  fi
  stat -f%z "$f" 2>/dev/null
}

has_polish_text() {
  local f="$1"
  local count
  # grep -c (nie -q) celowo: pod "set -o pipefail" "grep -q" zamyka potok
  # wczesniej i wysyla SIGPIPE do "strings" na duzym pliku, co daje falszywe
  # "NIE" mimo poprawnego patcha. "grep -c" czyta do konca, wiec nie SIGPIPE'uje.
  count=$(strings "$f" 2>/dev/null | grep -c "Krowobij" || true)
  [[ "${count:-0}" -gt 0 ]]
}

print_patch_plan() {
  local patches="$1"
  echo "Bundle do instalacji:"
  local name patch
  for name in "${PATCH_BUNDLES[@]}"; do
    patch="$patches/$name"
    if [[ -f "$patch" ]]; then
      echo "  + $name ($(file_size "$patch") B)"
    else
      echo "  - $name (brak w patches/)"
    fi
  done
}

install_all_patches() {
  local patches="$1"
  local game_streaming="$2"
  local backup="$3"
  local name
  for name in "${PATCH_BUNDLES[@]}"; do
    install_bundle "$name" "$patches" "$game_streaming" "$backup"
    if [[ -f "$patches/$name" ]]; then
      verify_bundle "$name" "$patches" "$game_streaming"
    fi
  done
}

restore_all_patches() {
  local backup="$1"
  local game_streaming="$2"
  local name
  for name in "${PATCH_BUNDLES[@]}"; do
    restore_bundle "$name" "$backup" "$game_streaming"
  done
}
