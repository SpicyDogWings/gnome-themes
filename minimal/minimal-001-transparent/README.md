# minimal-001-transparent

Tema propio, **minimalista monocromático y translúcido**. Estado: **GTK3
hecho**, **GTK4 aplicado** (claro + dark automático), **Shell incluido** (clara
+ oscura).

> Versión **translúcida**. La versión **sólida** (opaca) es `minimal-001`.
> En el shell, los fondos usan gradientes `rgba` que reemplazan al color
> opaco -> se ve el wallpaper a través (glass). En GTK, `bg`/`base`/`surface`
> van con alpha (requiere que la app soporte ventanas con alpha; no todas lo
> hacen).

Estética: **monocromo** (grayscale), esquinas **6px**, bordes finos de **1px** y
un **relieve suave moderno** (gradiente vertical sutil + highlight interior
arriba). Sin color de acento: selección/hover/activo son escalones de gris.
**Dark = casi negro** (`bg #0d0d0d`), **light = gris muy claro** (`bg #f4f4f4`).

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

Tema minimal monocromo completo: base Adwaita + paleta propia + reglas (flát,
radio 6px, bordes de 1px, relieve suave). Dos variantes:

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
forzado a **6px** y `-st-accent-color` **horneado a gris** (para que sea
monocromo: ese color lo setea el sistema y el tema no lo puede redefinir). Los
overrides (con la paleta literal + gradientes `background-gradient-*`) van al
final de cada archivo.

Necesita la extensión **User Themes**. Activar (Tweaks → Apariencia → Shell, o):

```bash
EXT=~/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com
GSETTINGS_SCHEMA_DIR="$EXT/schemas" \
  gsettings set org.gnome.shell.extensions.user-theme name minimal-001        # clara
# o: ... name minimal-001-dark                                                # oscura
```

Regenerar los CSS del shell (tras un update del shell). El builder toma el base del
`gnome-shell-theme.gresource`, le fuerza radio **6px**, hornea el accent del sistema
a gris y agrega los overrides — genera la versión sólida y la transparente:

```bash
./minimal/build-shell.py
```

## Notas

- GTK4 se edita en `gtk-4.0/gtk.css` (colores con nombres libadwaita).
- El tema de Shell se edita al final de `gnome-shell/gnome-shell-<light|dark>.css`
  (bloque "SHELL OVERRIDES").
- Radio pequeño en un solo lugar: `gtk-3.0/rules.css` y el base del shell.
