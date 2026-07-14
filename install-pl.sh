#!/usr/bin/env bash
# Wrapper — przekierowuje do instalatora dla biezacego systemu.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# W repo prywatnym instalatory leza obok wrappera, w paczce release w installers/.
SUB="$ROOT"
[[ -d "$ROOT/installers" ]] && SUB="$ROOT/installers"
case "$(uname -s)" in
  Linux*)  exec "$SUB/linux/install-pl.sh" "$@" ;;
  Darwin*) exec "$SUB/macos/install-pl.sh" "$@" ;;
  *)
    echo "Na Windows uruchom: installers\\windows\\install-pl.bat"
    exit 1
    ;;
esac
