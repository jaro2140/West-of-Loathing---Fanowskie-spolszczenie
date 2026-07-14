#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SUB="$ROOT"
[[ -d "$ROOT/installers" ]] && SUB="$ROOT/installers"
case "$(uname -s)" in
  Linux*)  exec "$SUB/linux/verify-install.sh" "$@" ;;
  Darwin*) exec "$SUB/macos/verify-install.sh" "$@" ;;
  *) echo "Windows: installers\\windows\\verify-install.bat"; exit 1 ;;
esac
