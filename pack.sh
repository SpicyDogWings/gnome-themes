#!/usr/bin/env bash
# ============================================================================
# gnome-themes · pack.sh
# ----------------------------------------------------------------------------
# Empaqueta los temas en dist/ (.zip y .tar.gz):
#   - la carpeta del tema va en la RAÍZ del archivo
#   - los symlinks se resuelven (paquete autocontenido)
#
# Uso:
#   ./pack.sh                 # empaqueta todos los temas del repo
#   ./pack.sh <dir> [<dir>…]  # empaqueta solo esos
#
# Usa el binario `stk` vendoreado en la raíz del repo (./stk).
# ============================================================================
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly STK_BIN="${SCRIPT_DIR}/stk"
readonly DIST_DIR="${SCRIPT_DIR}/dist"

# stk vendoreado. OJO: `stk log` no emite '\n' final (v0.2.x) -> lo agrega el wrapper.
stk() {
  "$STK_BIN" "$@"
  local rc=$?
  [[ "${1:-}" == log ]] && printf '\n'
  return "$rc"
}

die() { stk log "$1" -v error; exit 1; }

# Lista los dirs de tema (los que tienen index.theme), salteando los gitignored.
list_themes() {
  local f d rel
  while IFS= read -r -d '' f; do
    d="${f%/index.theme}"
    rel="${d#"$SCRIPT_DIR"/}"
    if git -C "$SCRIPT_DIR" check-ignore -q -- "$rel" 2>/dev/null; then
      continue
    fi
    printf '%s\n' "$d"
  done < <(find "$SCRIPT_DIR" -maxdepth 4 -name index.theme -not -path '*/.git/*' -print0)
}

main() {
  [[ -x "$STK_BIN" ]] || { printf 'Falta el binario stk en %s\n' "$STK_BIN" >&2; exit 1; }
  command -v tar >/dev/null 2>&1 || die "Falta el comando 'tar'"
  command -v zip >/dev/null 2>&1 || die "Falta el comando 'zip'"
  stk log "Empaquetando temas en dist/"

  local -a themes=()
  if [[ "$#" -ge 1 ]]; then
    themes=("$@")
  else
    local d
    while IFS= read -r d; do themes+=("$d"); done < <(list_themes)
  fi
  [[ "${#themes[@]}" -gt 0 ]] || die "No encontré ningún tema (index.theme) en ${SCRIPT_DIR}"

  mkdir -p -- "$DIST_DIR"

  local theme_dir id parent
  for theme_dir in "${themes[@]}"; do
    if [[ ! -f "${theme_dir}/index.theme" ]]; then
      stk log "Salteo ${theme_dir} (sin index.theme)" -v warning
      continue
    fi
    id="$(basename -- "$theme_dir")"
    parent="$(dirname -- "$theme_dir")"

    # .tar.gz  (-h: dereferencia symlinks -> autocontenido)
    tar -czhf "${DIST_DIR}/${id}.tar.gz" -C "$parent" "$id"
    stk log "dist/${id}.tar.gz" -v success

    # .zip  (zip sigue los symlinks por defecto -> autocontenido)
    ( cd "$parent" && zip -qr "${DIST_DIR}/${id}.zip" "$id" )
    stk log "dist/${id}.zip" -v success
  done

  stk log "Listo. Paquetes en ${DIST_DIR}" -v success
  ls -lh "$DIST_DIR"
}

main "$@"
