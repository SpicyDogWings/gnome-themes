# retro-001

Tema propio. Estado: **GTK3 hecho (no aplicado)**, **GTK4 aplicado** (claro + dark automático).

## Estructura

```
gtk-themes/                  # repo
├── install.sh               # instalador (copia a ~/.local/share + override GTK4 + gsettings)
├── stk                      # binario STK vendoreado (logging)
├── Orchis/                  # (gitignored) dependencia
└── retro/retro-001/         # el tema
    ├── index.theme          # "ficha" del tema
    ├── README.md
    ├── gtk-3.0/
    │   ├── palette.css      # paleta GTK3 (fuente única) + alias theme_*
    │   ├── gtk.css          # @import Adwaita + palette.css + reglas
    │   └── gtk-dark.css     # symlink a gtk.css
    └── gtk-4.0/
        └── gtk.css          # GTK4/libadwaita: claro + dark automático
```

## GTK3

- `./install.sh` copia el tema a `~/.local/share/themes/retro-001` y setea
  `gtk-theme` con gsettings (o elegilo en Tweaks → Apariencia → Legacy Applications).
- Hot reload (verificado): recrear el tema por nombre relee los archivos desde disco:
  ```bash
  gsettings set org.gnome.desktop.interface gtk-theme Adwaita
  gsettings set org.gnome.desktop.interface gtk-theme retro-001
  ```

## GTK4 / libadwaita

En GNOME 50 las apps GTK4 usan **libadwaita**, que **no** lee temas de
`~/.local/share/themes`. La única vía real es un override de usuario:

```
~/.config/gtk-4.0/gtk.css
```

`gtk-4.0/gtk.css` está pensado justo para eso (archivo único, autocontenido).

**Está aplicado** vía `./install.sh`, que copia `gtk-4.0/gtk.css` a
`~/.config/gtk-4.0/gtk.css` (con backup del actual como `gtk.css.bak.<fecha>`
si es distinto):

```bash
./install.sh              # autodetecta el tema del repo (salteando los gitignored)
./install.sh <dir-tema>   # o pasale el dir explícito
```

Revertir: restaurar el backup (`gtk.css.bak.<fecha>`).

### Variante dark (automática)

El mismo `gtk-4.0/gtk.css` trae las dos variantes: la paleta clara por
defecto y un bloque `@media (prefers-color-scheme: dark)` que **redefine solo
las claves que cambian** (`bg`, `fg`, `base`, `surface`, `border`,
`bevel_light`, `bevel_dark`, `hover`, `insensitive_fg_color`). `@accent`
queda igual, así que **una sola clave sigue mandando sobre todo el azul**.

GTK enlaza `prefers-color-scheme` de este provider al `color-scheme` del
sistema, así que la variante dark **se activa sola** al poner GNOME en modo
oscuro (no hay que cambiar archivos ni symlinks):

```bash
gsettings set org.gnome.desktop.interface color-scheme prefer-dark   # dark
gsettings set org.gnome.desktop.interface color-scheme default       # claro
```

## Notas

- GTK4 se edita en `gtk-4.0/gtk.css` (colores con nombres libadwaita).
- El shell de GNOME es aparte (`gnome-shell/` + extensión User Themes).
