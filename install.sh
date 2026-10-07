#!/usr/bin/env bash
# ============================================================================
# gnome-themes · install.sh
# ----------------------------------------------------------------------------
# Instala TODOS los temas del repo en el usuario actual:
#   - copia cada tema a  ~/.local/share/themes/<id>          (lo lee GTK3/Shell)
#   - instala el override GTK4 en ~/.config/gtk-4.0/gtk.css  (con backup)
#   - setea el tema GTK3 con gsettings (o desde Tweaks)
#
# Uso:
#   ./install.sh                 # instala todos los temas del repo
#   ./install.sh <dir> [<dir>…]  # instala solo esos
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
  stk log "Instalando temas"

  local -a themes=()
  if [[ "$#" -ge 1 ]]; then
    themes=("$@")
  else
    local d
    while IFS= read -r d; do themes+=("$d"); done < <(list_themes)
  fi
  [[ "${#themes[@]}" -gt 0 ]] || die "No encontré ningún tema (index.theme) en ${SCRIPT_DIR}"

  local gtk4_src="" gtk3_id=""
  local theme_dir id dest
  for theme_dir in "${themes[@]}"; do
    if [[ ! -f "${theme_dir}/index.theme" ]]; then
      stk log "Salteo ${theme_dir} (sin index.theme)" -v warning
      continue
    fi
    id="$(basename -- "$theme_dir")"
    dest="${THEMES_DIR}/${id}"
    if [[ -z "$id" || "$id" == "/" || "$dest" != "${THEMES_DIR}/"* ]]; then
      die "id inválido: '${id}'"
    fi
    mkdir -p -- "$THEMES_DIR"
    if [[ -e "$dest" || -L "$dest" ]]; then
      stk log "Reemplazando ${dest}" -v warning
      rm -rf -- "$dest"
    fi
    cp -a -- "$theme_dir" "$dest"
    stk log "Tema copiado a ${dest}" -v success

    # el tema "completo" aporta el override GTK4 y el gtk-theme de GTK3
    [[ -f "${theme_dir}/gtk-4.0/gtk.css" ]] && gtk4_src="${theme_dir}/gtk-4.0/gtk.css"
    [[ -f "${theme_dir}/gtk-3.0/gtk.css" ]] && gtk3_id="$id"
  done

  # --- override GTK4 (con backup del actual) --------------------------------
  if [[ -n "$gtk4_src" ]]; then
    mkdir -p -- "$GTK4_DIR"
    if [[ -L "$GTK4_CSS" && ! -e "$GTK4_CSS" ]]; then
      stk log "El gtk.css actual es un symlink roto -> $(readlink -- "$GTK4_CSS")" -v warning
      printf '%s\n' "$(readlink -- "$GTK4_CSS")" > "${GTK4_CSS}.bak.${STAMP}.symlink-target"
    elif [[ -e "$GTK4_CSS" ]]; then
      if cmp -s -- "$GTK4_CSS" "$gtk4_src"; then
        stk log "El gtk.css actual ya es el del tema (sin backup)"
      else
        cp -aL -- "$GTK4_CSS" "${GTK4_CSS}.bak.${STAMP}"
        stk log "Backup del gtk.css actual -> ${GTK4_CSS}.bak.${STAMP}"
      fi
    fi
    rm -f -- "$GTK4_CSS"
    cp -a -- "$gtk4_src" "$GTK4_CSS"
    stk log "Override GTK4 instalado -> ${GTK4_CSS}" -v success
  fi

  # --- tema GTK3 (GNOME) ----------------------------------------------------
  if [[ -n "$gtk3_id" ]]; then
    if command -v gsettings >/dev/null 2>&1; then
      gsettings set org.gnome.desktop.interface gtk-theme "$gtk3_id"
      stk log "GTK3: gtk-theme = ${gtk3_id}  (o elegilo en Tweaks)" -v success
    else
      stk log "Sin gsettings: seteá el tema GTK3 desde Tweaks" -v warning
    fi
  fi

  stk log "Listo. Reiniciá las apps GTK para ver los cambios." -v success
}

main "$@"
