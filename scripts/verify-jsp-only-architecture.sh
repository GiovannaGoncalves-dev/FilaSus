#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

failures=0

check_absent() {
  local description="$1"
  local pattern="$2"
  shift 2

  if rg -n "$pattern" "$@"; then
    echo "ERRO: $description" >&2
    failures=1
  fi
}

check_absent \
  "JSPs e JavaScript de producao ainda fazem requisicoes fetch/API." \
  'fetch\s*\(|\bapi\s*\(' \
  src/main/webapp/jsp src/main/webapp/js

check_absent \
  "JSPs e JavaScript de producao ainda referenciam rotas /api/." \
  '/api/' \
  src/main/webapp/jsp src/main/webapp/js

check_absent \
  "O backend ainda declara ou trata rotas /api/." \
  '"/api/|startsWith\("/api|equals\("/api' \
  src/main/java

if find src/main/java/br/com/filasus/controller/api -type f -name '*.java' -print -quit 2>/dev/null | grep -q .; then
  echo "ERRO: o package controller/api ainda existe." >&2
  failures=1
fi

if [[ "$failures" -ne 0 ]]; then
  exit 1
fi

echo "OK: a camada web usa somente navegacao e formularios JSP/Servlet."
