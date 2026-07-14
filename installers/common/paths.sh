# Wspolna logika instalatorow (bash).
# Uzycie: source "$(dirname "$0")/../common/paths.sh"

# Kolejnosc instalacji bundle (core, house, main_scene)
PATCH_BUNDLES=(core house main_scene)

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
