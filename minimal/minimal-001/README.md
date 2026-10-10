# minimal-001

Tema propio, **minimalista**. Estado: **GTK3 hecho**, **GTK4 aplicado** (claro +
dark automático), **Shell incluido** (chara + oscura).

Estética: casi monocromo, esquinas **6px**, bordes finos de **1px**, flát (sin
bisel, sin gradientes, sin sombras fuertes). Acento azul apagado solo para foco
y selección. **Dark = casi negro** (`bg #0e0e10`), **light = gris muy claro**
(`bg #f4f4f5`).

## Estructura

```
gtk-themes/                    # repo
├── install.sh                 # instalador (copia a ~/.local/share + override GTK4 + gsettings)
├── stk                        # binario STK vendoreado (logging)
├── Orchis/                    # (gitignored) dependencia
└── minimal/
    ├── minimal-001/           # el tema
    │   ├── index.theme        # "ficha" del tema
    │   ├── README.md
    │   ├── gtk-3.0/
    │   │   ├── palette.css      # paleta clara (fuente única) + alias
    │   │   ├── palette-dark.css # paleta oscura
    │   │   ├── rules.css        # reglas minimal compartidas (flát, 6px, 1px)
    │   │   ├── gtk.css          # @import Adwaita claro + palette + rules
    │   │   └── gtk-dark.css     # @import Adwaita dark + palette-dark + rules
    │   ├── gtk-4.0/
    │   │   └── gtk.css          # GTK4/libadwaita: claro + dark automático
    │   └── gnome-shell/
    │       ├── gnome-shell.css        # symlink a la variante activa
    │       ├── gnome-shell-light.css  # base del shell + overrides minimal (clara)
    │       └── gnome-shell-dark.css   # base del shell + overrides minimal (oscura)
    └── minimal-001-dark/      # solo shell oscura (entrada aparte en Tweaks)
        ├── index.theme
        └── gnome-shell/gnome-shell.css -> ../../minimal-001/gnome-shell/gnome-shell-dark.css
```

## GTK3

Tema minimal completo: base Adwaita + paleta propia + reglas (flát, radio 6px,
bordes de 1px). Dos variantes:

- `gtk.css` → **clara** (base Adwaita claro + `palette.css` + `rules.css`)
- `gtk-dark.css` → **oscura** (base Adwaita dark + `palette-dark.css` + `rules.css`)

GTK3 elige la variante con `gtk-application-prefer-dark-theme` (no sigue el
`color-scheme` del sistema como GTK4).

- `./install.sh minimal/minimal-001` copia el tema a `~/.local/share/themes/minimal-001`
  y setea `gtk-theme` con gsettings (o en Tweaks → Apariencia → Legacy Applications).
- Hot reload:
  ```bash
  gsettings set org.gnome.desktop.interface gtk-theme Adwaita
  gsettings set org.gnome.desktop.interface gtk-theme minimal-001
  ```

## GTK4 / libadwaita

En GNOME las apps GTK4 usan **libadwaita**, que **no** lee temas de
`~/.local/share/themes`. La vía real es un override de usuario:

```
~/.config/gtk-4.0/gtk.css
```

`gtk-4.0/gtk.css` está pensado justo para eso (archivo único, autocontenido).
Se instala con:

```bash
./install.sh minimal/minimal-001    # solo este tema
```

> Ojo: `./install.sh` sin argumentos instala **todos** los temas y deja como
> override GTK4 el último que encuentre. Si tenés más de un tema completo
> (retro-001, minimal-001), pasá el tema explícito.

### Variante dark (automática)

El mismo `gtk-4.0/gtk.css` trae las dos variantes: la paleta clara por defecto y
un bloque `@media (prefers-color-scheme: dark)` que redefine las claves que
cambian (`bg`, `fg`, `fg_dim`, `base`, `surface`, `hover`, `border`, `accent`).
GTK enlaza `prefers-color-scheme` al `color-scheme` del sistema, así que la
variante dark **se activa sola**:

```bash
gsettings set org.gnome.desktop.interface color-scheme prefer-dark   # dark
gsettings set org.gnome.desktop.interface color-scheme default       # claro
```

## GNOME Shell

Dos variantes (St/libcroco **no** soporta `@media` ni `@define-color`):

- `gnome-shell/gnome-shell-light.css` → base del shell + overrides minimal (clara)
- `gnome-shell/gnome-shell-dark.css` → ídem (oscura)
- `gnome-shell/gnome-shell.css` → **symlink** a la activa (por defecto, clara)

Para que Tweaks liste la variante oscura como entrada aparte existe
`minimal-001-dark/` (solo-shell), cuyo `gnome-shell/gnome-shell.css` apunta acá.

El base es el CSS stock del shell (extraído del gresource) con el `border-radius`
forzado a **6px**; los overrides (con la paleta literal) van al final de cada
archivo.

Necesita la extensión **User Themes**. Activar (Tweaks → Apariencia → Shell, o):

```bash
EXT=~/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com
GSETTINGS_SCHEMA_DIR="$EXT/schemas" \
  gsettings set org.gnome.shell.extensions.user-theme name minimal-001        # clara
# o: ... name minimal-001-dark                                                # oscura
```

Regenerar el base tras un update del shell (y volver a forzar `border-radius: 6px`):

```bash
gresource extract /usr/share/gnome-shell/gnome-shell-theme.gresource \
  /org/gnome/shell/theme/gnome-shell-light.css   # o -dark.css
```

## Notas

- GTK4 se edita en `gtk-4.0/gtk.css` (colores con nombres libadwaita).
- El tema de Shell se edita al final de `gnome-shell/gnome-shell-<light|dark>.css`
  (bloque "SHELL OVERRIDES").
- Radio pequeño en un solo lugar: `gtk-3.0/rules.css` y el base del shell.
