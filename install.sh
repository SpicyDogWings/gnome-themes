#!/usr/bin/env bash
# ============================================================================
# retro-001 · install.sh
# ----------------------------------------------------------------------------
# Instala el tema en el usuario actual:
#   1) copia el tema a  ~/.local/share/themes/<id>            (lo lee GTK3)
#   2) instala el override GTK4 en ~/.config/gtk-4.0/gtk.css  (con backup)
#   3) setea el tema GTK3 con gsettings (o desde Tweaks)
#
# Uso:
#   ./install.sh              # autodetecta el tema del repo
#   ./install.sh <dir-tema>   # usa ese dir (debe tener index.theme)
#
# Usa el binario `stk` vendoreado en la raíz del repo (./stk).
# ============================================================================
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly STK_BIN="${SCRIPT_DIR}/stk"

# stk vendoreado. OJO: `stk log` no emite '\n' final (v0.2.x) -> lo agrega el wrapper.
stk() {
  "$STK_BIN" "$@"
  local rc=$?
  [[ "${1:-}" == log ]] && printf '\n'
  return "$rc"
}

readonly THEMES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/themes"
readonly GTK4_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
readonly GTK4_CSS="${GTK4_DIR}/gtk.css"
readonly STAMP="$(date +%Y%m%d-%H%M%S)"

die() { stk log "$1" -v error; exit 1; }

# Detecta el dir del tema (el que tiene index.theme), salteando los ignorados
# por git (p.ej. Orchis/). Deja el resultado en THEME_DIR.
THEME_DIR=""
detect_theme() {
  local -a found=()
  local f d rel
  while IFS= read -r -d '' f; do
    d="${f%/index.theme}"
    rel="${d#"$SCRIPT_DIR"/}"
    if git -C "$SCRIPT_DIR" check-ignore -q -- "$rel" 2>/dev/null; then
      continue
    fi
    found+=("$d")
  done < <(find "$SCRIPT_DIR" -maxdepth 4 -name index.theme -not -path '*/.git/*' -print0)

  if [[ "${#found[@]}" -eq 0 ]]; then
    die "No encontré ningún tema (index.theme) en ${SCRIPT_DIR}"
  elif [[ "${#found[@]}" -gt 1 ]]; then
    stk log "Hay varios temas; pasá el dir como argumento:" -v error
    printf '  %s\n' "${found[@]}"
    exit 1
  fi
  THEME_DIR="${found[0]}"
}

main() {
  [[ -x "$STK_BIN" ]] || { printf 'Falta el binario stk en %s\n' "$STK_BIN" >&2; exit 1; }
  stk log "Instalando tema retro-001"

  local theme_dir
  if [[ "$#" -ge 1 ]]; then
    theme_dir="$1"
  else
    detect_theme
    theme_dir="$THEME_DIR"
  fi
  [[ -f "${theme_dir}/index.theme" ]]       || die "No es un tema (falta index.theme): ${theme_dir}"
  [[ -f "${theme_dir}/gtk-4.0/gtk.css" ]]   || die "Falta ${theme_dir}/gtk-4.0/gtk.css"

  local id
  id="$(basename -- "$theme_dir")"
  stk log "Tema: ${theme_dir}  (id: ${id})"

  # --- 1) copiar el tema a ~/.local/share/themes/<id> -----------------------
  mkdir -p -- "$THEMES_DIR"
  local dest="${THEMES_DIR}/${id}"
  if [[ -z "$id" || "$id" == "/" || "$dest" != "${THEMES_DIR}/"* ]]; then
    die "id inválido: '${id}'"
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    stk log "Reemplazando instalación previa en ${dest}" -v warning
    rm -rf -- "$dest"
  fi
  cp -a -- "$theme_dir" "$dest"
  stk log "Tema copiado a ${dest}" -v success

  # --- 2) override GTK4 (con backup del actual) -----------------------------
  mkdir -p -- "$GTK4_DIR"
  if [[ -L "$GTK4_CSS" && ! -e "$GTK4_CSS" ]]; then
    stk log "El gtk.css actual es un symlink roto -> $(readlink -- "$GTK4_CSS")" -v warning
    printf '%s\n' "$(readlink -- "$GTK4_CSS")" > "${GTK4_CSS}.bak.${STAMP}.symlink-target"
  elif [[ -e "$GTK4_CSS" ]]; then
    if cmp -s -- "$GTK4_CSS" "${theme_dir}/gtk-4.0/gtk.css"; then
      stk log "El gtk.css actual ya es el del tema (sin backup)"
    else
      cp -aL -- "$GTK4_CSS" "${GTK4_CSS}.bak.${STAMP}"
      stk log "Backup del gtk.css actual -> ${GTK4_CSS}.bak.${STAMP}"
    fi
  fi
  rm -f -- "$GTK4_CSS"
  cp -a -- "${theme_dir}/gtk-4.0/gtk.css" "$GTK4_CSS"
  stk log "Override GTK4 instalado -> ${GTK4_CSS}" -v success

  # --- 3) setear el tema GTK3 (GNOME) ---------------------------------------
  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "$id"
    stk log "GTK3: gtk-theme = ${id}  (o elegilo en Tweaks > Apariencia)" -v success
  else
    stk log "Sin gsettings: seteá el tema GTK3 desde Tweaks (Legacy Applications)" -v warning
  fi

  stk log "Listo. Reiniciá las apps GTK para ver los cambios." -v success
}

main "$@"
