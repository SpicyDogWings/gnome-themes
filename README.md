# gnome-themes

Colección de temas **GTK / GNOME** propios. Dos estéticas: **retro** (bisel 3D,
esquinas rectas, paleta beige/oscura) y **minimal** (flat, esquinas chicas de
6px, casi monocromo, dark casi negro). Incluyen **variante clara y oscura
automática** (GTK4 y Shell siguen el modo oscuro del sistema).

Probado en **GNOME Shell 50.5 / GTK 4.22**.

## Temas

| Tema | Estilo | GTK3 | GTK4 | Shell | Estado |
|------|--------|:----:|:----:|:-----:|--------|
| [`retro-001`](retro/retro-001/) | Retro OS · bisel 3D · beige + acento azul · dark automático | ✅ | ✅ | ✅ | usable |
| [`minimal-001`](minimal/minimal-001/) | Minimal · flat 6px · monocromo + relieve suave · dark automático | ✅ | ✅ | ✅ | usable |
| [`minimal-001-transparent`](minimal/minimal-001-transparent/) | Idem pero **translúcido** (shell glass + GTK con alpha) | ✅ | ✅ | ✅ | usable |

> `Orchis/` (gitignored) es una dependencia de terceros, **no** es un tema propio.

## Requisitos

- **GNOME** (probado en Shell 50.5) con GTK 4.22 / libadwaita.
- `gsettings` — para setear el tema GTK3.
- `stk` — el instalador usa el binario **vendoreado** `./stk`, no hace falta instalarlo.
- `python3` + `gresource` — solo para regenerar los CSS del shell (`minimal/build-shell.py`).

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

> **Ojo — un solo override GTK4.** El override de GTK4 es **un archivo**
> (`~/.config/gtk-4.0/gtk.css`). `./install.sh` sin argumentos instala **todos**
> los temas y deja el override del **último** que encuentre. Si tenés más de un
> tema completo (`retro-001`, `minimal-001`, `minimal-001-transparent`), pasá el
> tema explícito: `./install.sh minimal/minimal-001`. El **shell** sí convive: se
> elige cualquiera de las entradas en Tweaks.

### Empaquetar (distribuir)

```bash
./pack.sh                 # todos los temas -> dist/<id>.zip y dist/<id>.tar.gz
./pack.sh <dir> [<dir>…]  # solo esos
```

Cada paquete lleva la **carpeta del tema en la raíz** y los **symlinks resueltos**
(autocontenido). `dist/` está en `.gitignore`.

### Modo oscuro (automático)

El override GTK4 trae la variante clara por defecto y un bloque
`@media (prefers-color-scheme: dark)` que redefine las claves que cambian. Se
activa solo al poner GNOME en oscuro:

```bash
gsettings set org.gnome.desktop.interface color-scheme prefer-dark   # oscuro
gsettings set org.gnome.desktop.interface color-scheme default       # claro
```

### Shell de GNOME

El tema de shell viene en **una entrada por carpeta** (Tweaks lista un tema de
shell por carpeta) y el motor CSS del shell (St/libcroco) **no** soporta `@media`
ni `@define-color`, así que **no** se puede tener claro+oscuro en un solo archivo
(como el de GTK4). Por eso cada variante es un archivo, y las entradas `-dark` son
**solo-shell** (un symlink al `gnome-shell-dark.css` del tema):

| Carpeta | Shell |
|---------|-------|
| `retro/retro-001/` | clara (retro) |
| `retro/retro-001-dark/` | oscura (retro) |
| `minimal/minimal-001/` | clara · sólida |
| `minimal/minimal-001-dark/` | oscura · sólida |
| `minimal/minimal-001-transparent/` | clara · translúcida |
| `minimal/minimal-001-transparent-dark/` | oscura · translúcida |

Requiere la extensión **User Themes**. Elegí el tema en
**Tweaks → Apariencia → Shell**. O por comando:

```bash
EXT=~/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com
GSETTINGS_SCHEMA_DIR="$EXT/schemas" \
  gsettings set org.gnome.shell.extensions.user-theme name minimal-001-dark
```

Los `gnome-shell.css` de `minimal` se **generan** con `minimal/build-shell.py`:

```bash
./minimal/build-shell.py
```

Extrae el base del `gnome-shell-theme.gresource`, fuerza radio 6px, hornea el
accent del sistema a gris y agrega los overrides (genera sólida + transparente).

## Estructura

```
gnome-themes/
├── install.sh               # instalador (copia a ~/.local/share + override GTK4 + gsettings)
├── pack.sh                  # empaqueta los temas en dist/ (.zip / .tar.gz)
├── stk                      # binario STK vendoreado (logging del instalador)
├── Orchis/                  # (gitignored) dependencia de terceros
├── retro/
│   ├── retro-001/           # tema completo (GTK3 + GTK4 + shell clara)
│   │   ├── index.theme      # "ficha" del tema
│   │   ├── README.md        # detalle del tema
│   │   ├── gtk-3.0/         # tema GTK3 (palette.css + reglas)
│   │   ├── gtk-4.0/         # override GTK4/libadwaita (claro + dark automático)
│   │   └── gnome-shell/     # tema de Shell (clara/oscura)
│   └── retro-001-dark/      # solo shell oscura (entrada aparte en Tweaks)
│       ├── index.theme
│       └── gnome-shell/gnome-shell.css -> ../../retro-001/gnome-shell/gnome-shell-dark.css
└── minimal/
    ├── build-shell.py       # genera los gnome-shell.css (sólida + transparente)
    ├── minimal-001/         # tema completo SÓLIDO (GTK3 + GTK4 + shell clara)
    │   ├── index.theme
    │   ├── README.md
    │   ├── gtk-3.0/
    │   ├── gtk-4.0/
    │   └── gnome-shell/     # tema de Shell (clara/oscura)
    ├── minimal-001-dark/    # solo shell oscura (entrada aparte en Tweaks)
    │   ├── index.theme
    │   └── gnome-shell/gnome-shell.css -> ../../minimal-001/gnome-shell/gnome-shell-dark.css
    ├── minimal-001-transparent/   # tema completo TRANSLÚCIDO (shell glass + GTK alpha)
    │   ├── index.theme
    │   ├── README.md
    │   ├── gtk-3.0/
    │   ├── gtk-4.0/
    │   └── gnome-shell/     # shell translúcida (clara/oscura)
    └── minimal-001-transparent-dark/  # solo shell oscura translúcida
        ├── index.theme
        └── gnome-shell/gnome-shell.css -> ../../minimal-001-transparent/gnome-shell/gnome-shell-dark.css
```

## Notas

- Cada tema es autocontenido en su carpeta: `index.theme` + `gtk-3.0/` + `gtk-4.0/`
  (+ `gnome-shell/` si trae Shell).
- En GNOME, las apps GTK4 usan **libadwaita**; la vía confiable para reestilarlas
  es el **override de usuario** `~/.config/gtk-4.0/gtk.css`.
