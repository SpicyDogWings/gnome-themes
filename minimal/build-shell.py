#!/usr/bin/env python3
"""build-shell.py — genera los gnome-shell.css de minimal-001.

Toma el CSS **stock** del shell (extraído de gnome-shell-theme.gresource), le
fuerza border-radius 6px, hornea el accent del sistema a gris y agrega el bloque
de overrides minimal. Genera las DOS versiones:

  - minimal-001/gnome-shell/             -> fondos OPACOS   (sólida)
  - minimal-001-transparent/gnome-shell/ -> fondos TRANSLÚCIDOS (glass)

St/libcroco NO soporta @media ni @define-color: el shell es de UNA sola
variante -> por eso se generan gnome-shell-light.css y gnome-shell-dark.css, y
las entradas "-dark" (solo-shell) son symlinks a la variante dark.

Uso:
    ./minimal/build-shell.py                 # regenera a partir del gresource
    SHELL_GRESOURCE=/ruta/theme.gresource ./minimal/build-shell.py

Requiere: `gresource` (glib), `python3`.
"""
from __future__ import annotations

import os
import pathlib
import re
import subprocess
import tempfile

RADIUS = "6px"
GRESOURCE = os.environ.get("SHELL_GRESOURCE", "/usr/share/gnome-shell/gnome-shell-theme.gresource")
GRESOURCE_PREFIX = "/org/gnome/shell/theme/"

HERE = pathlib.Path(__file__).resolve().parent          # .../minimal
SOLID_DIR = HERE / "minimal-001" / "gnome-shell"
TRANS_DIR = HERE / "minimal-001-transparent" / "gnome-shell"


# --------------------------------------------------------------------------- #
# transformaciones del base
# --------------------------------------------------------------------------- #
def force_radius(css: str) -> str:
    def repl(m: re.Match) -> str:
        raw = m.group(1).strip()
        imp = ""
        if raw.endswith("!important"):
            raw = raw[: -len("!important")].strip()
            imp = " !important"
        parts = [("0" if re.fullmatch(r"0(\.0+)?(px)?", p) else RADIUS) for p in raw.split()]
        return "border-radius: " + " ".join(parts) + imp + ";"
    return re.sub(r"border-radius:\s*([^;]+);", repl, css)


def add_important_accent(css: str) -> str:
    """GNOME carga su tema por DEFECTO debajo del de usuario; las reglas del
    default que usan -st-accent-color le ganan a las nuestras -> forzamos
    !important en toda declaración que use el accent (antes de reemplazarlo)."""
    def repl(m: re.Match) -> str:
        decl = m.group(0)
        if "-st-accent" in decl and ":" in decl and "!important" not in decl:
            return decl[:-1].rstrip() + " !important;"
        return decl
    return re.sub(r"[^;{}]+;", repl, css)


def gray_out(css: str) -> str:
    """Monocromo puro: convierte todo color con tinte a su gris por luminancia."""
    def rgba_repl(m: re.Match) -> str:
        r, g, b = int(m.group(1)), int(m.group(2)), int(m.group(3))
        L = round(0.2126 * r + 0.7152 * g + 0.0722 * b)
        return f"rgba({L}, {L}, {L}, {m.group(4)})"

    css = re.sub(r"rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([0-9.]+)\s*\)", rgba_repl, css)

    def hex_repl(m: re.Match) -> str:
        h = m.group(1)
        if len(h) == 3:
            h = "".join(c * 2 for c in h)
        r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
        L = round(0.2126 * r + 0.7152 * g + 0.0722 * b)
        return f"#{L:02x}{L:02x}{L:02x}"

    return re.sub(r"#([0-9a-fA-F]{6})\b", hex_repl, css)


# --------------------------------------------------------------------------- #
# paletas literales (St no soporta @define-color en el shell)
# --------------------------------------------------------------------------- #
LIGHT = {
    "name": "LIGHT",
    "bg": "#f4f4f4", "base": "#ffffff", "surface": "#ececec", "surf_top": "#fbfbfb",
    "surface_hi": "#e3e3e3", "border": "#d9d9d9",
    "fg": "#1b1b1b", "fg_dim": "#6b6b6b",
    "accent": "#d5d5d5", "acc_top": "#e9e9e9", "accent_fg": "#1b1b1b", "focus": "#8a8a8a",
    "hl_line": "rgba(255, 255, 255, 0.95)", "shade": "rgba(0, 0, 0, 0.10)",
}
DARK = {
    "name": "DARK",
    "bg": "#0d0d0d", "base": "#131313", "surface": "#1a1a1a", "surf_top": "#242424",
    "surface_hi": "#242424", "border": "#2e2e2e",
    "fg": "#e9e9e9", "fg_dim": "#8b8b8b",
    "accent": "#373737", "acc_top": "#454545", "accent_fg": "#ffffff", "focus": "#8e8e8e",
    "hl_line": "rgba(255, 255, 255, 0.10)", "shade": "rgba(0, 0, 0, 0.45)",
}


HEADER = """/* ============================================================================
 * minimal-001 — GNOME Shell theme · {variant} variant · {mode}
 * ----------------------------------------------------------------------------
 * = stock shell base (block "generated, DO NOT EDIT", with border-radius
 *   forced to {radius}) + MINIMAL MONO overrides at the end.
 *
 * {mode_note}
 * Monochrome (grayscale). The system accent is baked to gray with !important
 * (GNOME loads its default theme underneath the user theme).
 * St does NOT support @media nor @define-color: each variant is a SINGLE file.
 *
 * Generado por minimal/build-shell.py — no editar a mano (salvo el bloque de
 * overrides de abajo, que vive en ese script).
 *
 * Base extraída con:
 *   gresource extract {gresource} \\
 *     {prefix}<light|dark>.css
 * ========================================================================== */
"""


def overrides(p: dict) -> str:
    surf = f"""  background-color: {p['surface']};
  background-gradient-start: {p['surf_top']};
  background-gradient-end: {p['surface']};
  background-gradient-direction: vertical;"""
    accl = f"""  background-color: {p['accent']};
  background-gradient-start: {p['acc_top']};
  background-gradient-end: {p['accent']};
  background-gradient-direction: vertical;"""
    return f"""
/* ============================================================================
 * minimal-001 — SHELL OVERRIDES · {p['name']} (mono)
 * ----------------------------------------------------------------------------
 * Estas reglas se generan desde minimal/build-shell.py.
 * Palette (literal, St has no @define-color):
 *   surface {p['surface']} · bg {p['bg']} · base {p['base']} · accent {p['accent']}
 *   border {p['border']} · fg {p['fg']} · fg_dim {p['fg_dim']}
 * Relief = vertical gradient + top-right inset highlight.
 * ========================================================================== */

/* --- Top bar: flat surface + hairline bottom border --- */
#panel {{
{surf}
  color: {p['fg']};
  height: 2.4em;
  border-bottom: 1px solid {p['border']};
  box-shadow: none;
}}
#panel:overview, #panel.unlock-screen, #panel.login-screen {{
  background-color: transparent;
  background-gradient-start: transparent;
  background-gradient-end: transparent;
  border-bottom: none;
  box-shadow: none;
}}
#panel .panel-button {{
  color: {p['fg']};
  border: 1px solid transparent;
  border-radius: {RADIUS};
  box-shadow: none;
}}
#panel .panel-button:hover, #panel .panel-button:focus {{
  background-color: {p['surface_hi']};
  background-gradient-start: {p['surf_top']};
  background-gradient-end: {p['surface_hi']};
  background-gradient-direction: vertical;
  box-shadow: inset -1px 1px 0 {p['hl_line']};
}}
#panel .panel-button:active, #panel .panel-button:checked {{
{accl}
  color: {p['accent_fg']};
  box-shadow: inset -1px 1px 0 {p['hl_line']};
}}
#panel .panel-button.clock-display {{ background: none; background-gradient-start: transparent; background-gradient-end: transparent; border: none; box-shadow: none; }}
#panel .panel-button#panelActivities .workspace-dot {{ background-color: {p['fg']}; }}

/* --- Menus / popovers (relief) --- */
.popup-menu, .candidate-popup-content {{ color: {p['fg']}; }}
.popup-menu-content, .candidate-popup-content {{
{surf}
  color: {p['fg']};
  border: 1px solid {p['border']};
  border-radius: {RADIUS};
  box-shadow: inset -1px 1px 0 {p['hl_line']};
}}
.popup-menu-item {{ color: {p['fg']}; border-radius: {RADIUS}; }}
.popup-menu-item:hover, .popup-menu-item:selected, .popup-menu-item:checked {{
{accl}
  color: {p['accent_fg']};
  box-shadow: inset -1px 1px 0 {p['hl_line']};
}}
.popup-menu-item:active {{ background-color: {p['accent']}; color: {p['accent_fg']}; }}
.popup-inactive-menu-item {{ color: {p['fg_dim']}; }}
.popup-sub-menu {{ background-color: {p['base']}; border: 1px solid {p['border']}; }}
.popup-sub-menu .popup-menu-item:hover, .popup-sub-menu .popup-menu-item:selected,
.popup-sub-menu .popup-menu-item:checked {{ {accl}
  color: {p['accent_fg']};
}}
.popup-separator-menu-item .popup-separator-menu-item-separator {{ background-color: {p['border']}; }}

/* --- Buttons (relief) --- */
.button, .icon-button {{
  color: {p['fg']};
{surf}
  border: 1px solid {p['border']};
  border-radius: {RADIUS};
  box-shadow: inset -1px 1px 0 {p['hl_line']};
}}
.button:hover, .icon-button:hover {{
  background-color: {p['surface_hi']};
  background-gradient-start: {p['surf_top']};
  background-gradient-end: {p['surface_hi']};
}}
.button:active, .icon-button:active,
.button:checked, .icon-button:checked {{
{accl}
  color: {p['accent_fg']};
  box-shadow: inset -1px 1px 0 {p['hl_line']};
}}
.button.default, .icon-button.default {{
{accl}
  color: {p['accent_fg']};
}}
.button:focus, .icon-button:focus {{ box-shadow: inset 0 0 0 1px {p['focus']}; }}

/* --- Quick settings (relief) --- */
.quick-toggle, .quick-toggle-menu, .quick-settings {{
{surf}
  border: 1px solid {p['border']};
}}
.quick-toggle:checked {{
{accl}
  color: {p['accent_fg']};
}}

/* --- Sliders / switches --- */
.slider {{ background-color: {p['base']}; border: 1px solid {p['border']}; }}
.slider:hover {{ {accl} }}
.toggle-switch {{ background-color: {p['base']}; border: 1px solid {p['border']}; }}
.toggle-switch:checked {{ {accl} }}

/* --- Entries (sunken) --- */
StEntry, .search-entry, .entry {{
  background-color: {p['base']};
  color: {p['fg']};
  border: 1px solid {p['border']};
  border-radius: {RADIUS};
  box-shadow: inset 0 1px 2px {p['shade']};
}}
StEntry:focus, .search-entry:focus {{ border-color: {p['focus']}; box-shadow: none; }}

/* --- OSD (relief) --- */
.osd-window, .osd-monitor-label {{
{surf}
  border: 1px solid {p['border']};
  border-radius: {RADIUS};
  box-shadow: inset -1px 1px 0 {p['hl_line']};
}}
.osd-window .level-bar {{ background-color: {p['accent']}; }}

/* --- Notifications (relief) --- */
.notification, .message, .message-list {{ background-color: {p['surface']}; }}
.message {{
{surf}
  border: 1px solid {p['border']};
  border-radius: {RADIUS};
  box-shadow: inset -1px 1px 0 {p['hl_line']};
}}
.message .message-header .message-close-button {{ background-color: {p['surface_hi']}; }}

/* --- Modal dialogs (relief) --- */
.modal-dialog, .end-session-dialog, .run-dialog, .prompt-dialog {{
{surf}
  border: 1px solid {p['border']};
  border-radius: {RADIUS};
  box-shadow: inset -1px 1px 0 {p['hl_line']};
}}

/* --- Dash / overview --- */
.dash-label {{ background-color: {p['surface']}; border: 1px solid {p['border']}; color: {p['fg']}; }}
.overview-tile:hover .overview-icon, .grid-search-result:hover .overview-icon {{
  background-color: {p['surface_hi']};
  background-gradient-start: {p['surf_top']};
  background-gradient-end: {p['surface_hi']};
}}
.overview-tile:focus .overview-icon, .overview-tile:selected .overview-icon {{
{accl}
}}

/* --- Search --- */
.search-section-content, .search-section .search-section-content {{ background-color: {p['surface']}; border: 1px solid {p['border']}; }}
.list-search-result:hover, .list-search-result:focus {{
{accl}
  color: {p['accent_fg']};
}}

/* --- Switchers (relief) --- */
.switcher-list {{
{surf}
  border: 1px solid {p['border']};
  box-shadow: inset -1px 1px 0 {p['hl_line']};
}}
.switcher-list .item-box:selected {{
{accl}
  color: {p['accent_fg']};
}}
.workspace-thumbnail-indicator {{ border: 1px solid {p['focus']}; }}

/* --- Calendar / datemenu --- */
.calendar, .datemenu-today-button, .events-button {{ background-color: {p['surface']}; }}
.calendar .calendar-day.calendar-today {{
{accl}
  color: {p['accent_fg']};
}}
.calendar .calendar-day:hover {{ background-color: {p['surface_hi']}; }}
.calendar .calendar-day-heading, .calendar .calendar-month-header .calendar-month-label {{ color: {p['fg_dim']}; }}
.datemenu-today-button:hover, .events-button:hover, .world-clocks-button:hover, .weather-button:hover {{ background-color: {p['surface_hi']}; }}
.world-clocks-button, .weather-button {{ background-color: {p['surface']}; }}
"""


def build(base_css: str, palette: dict, translucent: bool) -> str:
    css = force_radius(base_css)
    css = add_important_accent(css)
    css = css.replace("-st-accent-fg-color", palette["accent_fg"])
    css = css.replace("-st-accent-color", palette["accent"])
    css = gray_out(css)

    ov = overrides(palette)
    if translucent:
        # En St el gradiente REEMPLAZA al color -> rgba translúcido = fondo glass.
        ov = re.sub(r"background-gradient-start:\s*[^;]+;",
                    f"background-gradient-start: {palette['hl_line']};", ov)
        ov = re.sub(r"background-gradient-end:\s*[^;]+;",
                    "background-gradient-end: rgba(255, 255, 255, 0);", ov)

    mode_note = ("TRANSLUCENT backgrounds (the rgba gradient replaces the opaque\n"
                 " * background color -> you see through, like a glass panel)."
                 if translucent else
                 "SOLID (opaque) backgrounds: the gradient stops are opaque colors.")
    header = HEADER.format(variant=palette["name"].title(), radius=RADIUS,
                           mode=("TRANSLUCENT" if translucent else "SOLID"),
                           mode_note=mode_note, gresource=GRESOURCE,
                           prefix=GRESOURCE_PREFIX)
    return header + css + ov


def extract(resource: str, dest: pathlib.Path) -> str:
    out = subprocess.run(["gresource", "extract", GRESOURCE, GRESOURCE_PREFIX + resource],
                         capture_output=True, text=True, check=True)
    dest.write_text(out.stdout, encoding="utf-8")
    return out.stdout


def emit(out_dir: pathlib.Path, stock_light: str, stock_dark: str, translucent: bool) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "gnome-shell-light.css").write_text(build(stock_light, LIGHT, translucent), encoding="utf-8")
    (out_dir / "gnome-shell-dark.css").write_text(build(stock_dark, DARK, translucent), encoding="utf-8")
    link = out_dir / "gnome-shell.css"
    if not (link.exists() or link.is_symlink()):
        link.symlink_to("gnome-shell-light.css")
    print(f"  {out_dir.relative_to(HERE)}  ({'transparent' if translucent else 'solid'})")


def main() -> None:
    if not pathlib.Path(GRESOURCE).is_file():
        raise SystemExit(f"No existe el gresource: {GRESOURCE}")
    with tempfile.TemporaryDirectory() as td:
        tmp = pathlib.Path(td)
        stock_light = extract("gnome-shell-light.css", tmp / "light.css")
        stock_dark = extract("gnome-shell-dark.css", tmp / "dark.css")
    print(f"Base: {GRESOURCE}")
    emit(SOLID_DIR, stock_light, stock_dark, translucent=False)
    emit(TRANS_DIR, stock_light, stock_dark, translucent=True)
    print("OK")


if __name__ == "__main__":
    main()
