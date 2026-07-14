#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SUB="$ROOT"
[[ -d "$ROOT/installers" ]] && SUB="$ROOT/installers"
case "$(uname -s)" in
  Linux*)  exec "$SUB/linux/restore-en.sh" "$@" ;;
  Darwin*) exec "$SUB/macos/restore-en.sh" "$@" ;;
  *) echo "Windows: installers\\windows\\restore-en.bat"; exit 1 ;;
esac
