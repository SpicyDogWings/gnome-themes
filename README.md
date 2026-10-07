# gnome-themes

Colección de temas **GTK / GNOME** propios con estética **retro**: bisel 3D
(raised/sunken), esquinas rectas y paleta beige/oscura. Incluyen **variante
clara y oscura automática** (sigue el modo oscuro del sistema).

Probado en **GNOME Shell 50.5 / GTK 4.22**.

## Temas

| Tema | Estilo | GTK3 | GTK4 | Shell | Estado |
|------|--------|:----:|:----:|:-----:|--------|
| [`retro-001`](retro/retro-001/) | Retro OS · bisel 3D · beige + acento azul · dark automático | ✅ | ✅ | ✅ | usable |

> `Orchis/` (gitignored) es una dependencia de terceros, **no** es un tema propio.

## Requisitos

- **GNOME** (probado en Shell 50.5) con GTK 4.22 / libadwaita.
- `gsettings` — para setear el tema GTK3.
- `stk` — el instalador usa el binario **vendoreado** `./stk`, no hace falta instalarlo.

## Instalar

```bash
git clone git@github.com:SpicyDogWings/gnome-themes.git
cd gnome-themes
./install.sh                 # autodetecta el tema del repo
./install.sh <dir-tema>      # o pasale un tema explícito
```

`install.sh` hace, en el usuario actual:

1. **Copia el tema** a `~/.local/share/themes/<id>` (ahí lo lee GTK3).
2. **Instala el override GTK4** en `~/.config/gtk-4.0/gtk.css`, con backup del
   actual como `gtk.css.bak.<fecha>` (si ya es el del tema, no genera backup).
3. **Setea el tema GTK3** con `gsettings set org.gnome.desktop.interface gtk-theme <id>`
   (o elegilo en *Tweaks → Apariencia → Legacy Applications*).

Después, reiniciá las apps GTK (Nautilus, etc.) para ver los cambios.

### Modo oscuro (automático)

El override GTK4 trae la variante clara por defecto y un bloque
`@media (prefers-color-scheme: dark)` que redefine las claves que cambian. Se
activa solo al poner GNOME en oscuro:

```bash
gsettings set org.gnome.desktop.interface color-scheme prefer-dark   # oscuro
gsettings set org.gnome.desktop.interface color-scheme default       # claro
```

### Shell de GNOME

El tema de shell viene en **dos entradas separadas**, porque Tweaks lista un tema
de shell **por carpeta** y el motor CSS del shell (St/libcroco) **no** soporta
`@media` ni `@define-color` (no se puede tener claro+oscuro en un archivo como el
de GTK4):

| Carpeta | Shell |
|---------|-------|
| `retro/retro-001/` | clara |
| `retro/retro-001-dark/` | oscura |

`retro-001-dark/` es **solo-shell**: su `gnome-shell/gnome-shell.css` es un symlink
a `retro-001/gnome-shell/gnome-shell-dark.css`.

Requiere la extensión **User Themes**. Elegí el tema en
**Tweaks → Apariencia → Shell** (`retro-001` o `retro-001-dark`). O por comando:

```bash
EXT=~/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com
GSETTINGS_SCHEMA_DIR="$EXT/schemas" \
  gsettings set org.gnome.shell.extensions.user-theme name retro-001-dark
```

## Estructura

```
gnome-themes/
├── install.sh               # instalador (copia a ~/.local/share + override GTK4 + gsettings)
├── stk                      # binario STK vendoreado (logging del instalador)
├── Orchis/                  # (gitignored) dependencia de terceros
└── retro/
    ├── retro-001/           # tema completo (GTK3 + GTK4 + shell clara)
    │   ├── index.theme      # "ficha" del tema
    │   ├── README.md        # detalle del tema
    │   ├── gtk-3.0/         # tema GTK3 (palette.css + reglas)
    │   ├── gtk-4.0/         # override GTK4/libadwaita (claro + dark automático)
    │   └── gnome-shell/     # tema de Shell (clara/oscura)
    └── retro-001-dark/      # solo shell oscura (entrada aparte en Tweaks)
        ├── index.theme
        └── gnome-shell/gnome-shell.css -> ../../retro-001/gnome-shell/gnome-shell-dark.css
```

## Notas

- Cada tema es autocontenido en su carpeta: `index.theme` + `gtk-3.0/` + `gtk-4.0/`
  (+ `gnome-shell/` si trae Shell).
- En GNOME, las apps GTK4 usan **libadwaita**; la vía confiable para reestilarlas
  es el **override de usuario** `~/.config/gtk-4.0/gtk.css`.
