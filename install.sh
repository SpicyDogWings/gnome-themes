#!/usr/bin/env bash
# ============================================================================
# gnome-themes · install.sh
# ----------------------------------------------------------------------------
# Instala los temas del repo en el usuario actual:
#   - copia cada tema a  ~/.local/share/themes/<id>          (lo lee GTK3/Shell)
#   - instala el override GTK4 en ~/.config/gtk-4.0/gtk.css  (con backup)
#   - setea el tema GTK3 con gsettings (o desde Tweaks)
#   - neutraliza el override de usuario de GTK3 (~/.config/gtk-3.0/gtk.css), con backup
#   - instala automáticamente la entrada <id>-dark (shell oscura) del tema
#
# Uso:
#   ./install.sh                      # instala todo; GTK = $DEFAULT_THEME
#   ./install.sh <dir|id> [<dir|id>…] # instala solo esos (+ su entrada -dark)
#
# Variables:
#   DEFAULT_THEME=minimal/minimal-001  # tema GTK en modo "instalar todo"
#
# Usa el binario `stk` vendoreado en la raíz del repo (./stk).
# ============================================================================
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly STK_BIN="${SCRIPT_DIR}/stk"
readonly DEFAULT_THEME="${DEFAULT_THEME:-minimal/minimal-001}"

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
# Ordenada para que el modo "instalar todo" sea determinista.
list_themes() {
  local f d rel
  while IFS= read -r -d '' f; do
    d="${f%/index.theme}"
    rel="${d#"$SCRIPT_DIR"/}"
    if git -C "$SCRIPT_DIR" check-ignore -q -- "$rel" 2>/dev/null; then
      continue
    fi
    printf '%s\n' "$d"
  done < <(find "$SCRIPT_DIR" -maxdepth 4 -name index.theme -not -path '*/.git/*' -print0 | sort -z)
}

# Acepta una ruta (relativa/absoluta) o el id de la carpeta del tema.
resolve_theme() {
  local t="${1%/}" d
  local candidate="$t"
  [[ "$candidate" != /* ]] && candidate="${SCRIPT_DIR}/${candidate}"
  if [[ -f "${candidate}/index.theme" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  while IFS= read -r d; do
    if [[ "$(basename -- "$d")" == "$t" ]]; then
      printf '%s\n' "$d"
      return 0
    fi
  done < <(list_themes)
  return 1
}

# Devuelve la entrada <id>-dark hermana, si existe (solo-shell).
dark_companion() {
  local theme_dir="$1" id parent
  id="$(basename -- "$theme_dir")"
  parent="$(dirname -- "$theme_dir")"
  if [[ "$id" != *-dark && -f "${parent}/${id}-dark/index.theme" ]]; then
    printf '%s\n' "${parent}/${id}-dark"
  fi
}

main() {
  [[ -x "$STK_BIN" ]] || { printf 'Falta el binario stk en %s\n' "$STK_BIN" >&2; exit 1; }
  stk log "Instalando temas"

  local -a requested=()
  if [[ "$#" -ge 1 ]]; then
    local arg resolved dark
    for arg in "$@"; do
      if ! resolved="$(resolve_theme "$arg")"; then
        die "No encontré el tema '${arg}' (pasá un dir con index.theme o su id)"
      fi
      requested+=("$resolved")
      dark="$(dark_companion "$resolved")"
      if [[ -n "$dark" ]]; then
        requested+=("$dark")
      fi
    done
  else
    local d
    while IFS= read -r d; do
      requested+=("$d")
      dark="$(dark_companion "$d")"
      if [[ -n "$dark" ]]; then
        requested+=("$dark")
      fi
    done < <(list_themes)
  fi

  # dedupe preservando orden
  local -a themes=()
  local -A seen=()
  local t
  for t in "${requested[@]}"; do
    if [[ -n "${seen[$t]:-}" ]]; then
      continue
    fi
    seen[$t]=1
    themes+=("$t")
  done
  [[ "${#themes[@]}" -gt 0 ]] || die "No encontré ningún tema (index.theme) en ${SCRIPT_DIR}"

  # Tema que aporta GTK3/GTK4. Con argumentos gana el último tema completo;
  # sin argumentos se usa DEFAULT_THEME (o el primer tema completo).
  local active_dir=""
  if [[ "$#" -ge 1 ]]; then
    for t in "${themes[@]}"; do
      if [[ -f "${t}/gtk-4.0/gtk.css" || -f "${t}/gtk-3.0/gtk.css" ]]; then
        active_dir="$t"
      fi
    done
  else
    active_dir="$(resolve_theme "$DEFAULT_THEME" || true)"
  fi
  if [[ -z "$active_dir" ]]; then
    for t in "${themes[@]}"; do
      if [[ -f "${t}/gtk-4.0/gtk.css" ]]; then
        active_dir="$t"
        break
      fi
    done
  fi

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
  done

  # el tema activo aporta el override GTK4 y el gtk-theme de GTK3
  if [[ -n "$active_dir" && -f "${active_dir}/gtk-4.0/gtk.css" ]]; then
    gtk4_src="${active_dir}/gtk-4.0/gtk.css"
  fi
  if [[ -n "$active_dir" && -f "${active_dir}/gtk-3.0/gtk.css" ]]; then
    gtk3_id="$(basename -- "$active_dir")"
  fi
  if [[ -n "$active_dir" ]]; then
    stk log "Tema GTK activo: $(basename -- "$active_dir")" -v success
  else
    stk log "No hay un tema GTK completo; solo se instalaron entradas de Shell" -v warning
  fi

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

    # --- override de usuario de GTK3 (pisa al tema si importa otra paleta) ---
    local GTK3_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0"
    local GTK3_CSS="${GTK3_DIR}/gtk.css"
    local neutral='/* gnome-themes: el tema se aplica via gtk-theme; sin override de usuario */'
    mkdir -p -- "$GTK3_DIR"
    if [[ -e "$GTK3_CSS" || -L "$GTK3_CSS" ]] && ! cmp -s <(printf '%s\n' "$neutral") "$GTK3_CSS"; then
      cp -aL -- "$GTK3_CSS" "${GTK3_CSS}.bak.${STAMP}" 2>/dev/null || true
      stk log "Backup del override GTK3 -> ${GTK3_CSS}.bak.${STAMP}"
    fi
    printf '%s\n' "$neutral" > "$GTK3_CSS"
    stk log "Override GTK3 neutralizado -> ${GTK3_CSS}" -v success
  fi

  stk log "Listo. Reiniciá las apps GTK para ver los cambios." -v success
}

main "$@"
