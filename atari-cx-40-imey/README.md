# atari-cx-40-imey

Tema propio. Estado: **GTK3 hecho (no aplicado)**, **GTK4 creado (no aplicado)**.

## Estructura

```
atari-cx-40-imey/
├── index.theme              # "ficha" del tema
├── README.md
├── gtk-3.0/
│   ├── palette.css          # paleta GTK3 (fuente única) + alias theme_*
│   ├── gtk.css              # @import Adwaita + palette.css + reglas
│   └── gtk-dark.css         # symlink a gtk.css
└── gtk-4.0/
    └── gtk.css              # GTK4/libadwaita: paleta con nombres libadwaita
```

## GTK3 (en pausa)

- El tema vive acá y está symlinkeado en `~/.local/share/themes/atari-cx-40-imey`.
- **Pero el override de usuario se restauró a Noctalia** (`~/.config/gtk-3.0/`),
  así que el look activo de GTK3 es el de antes.
- Hot reload (verificado): recrear el tema por nombre relee los archivos desde disco:
  ```bash
  gsettings set org.gnome.desktop.interface gtk-theme Adwaita
  gsettings set org.gnome.desktop.interface gtk-theme atari-cx-40-imey
  ```

## GTK4 / libadwaita

En GNOME 50 las apps GTK4 usan **libadwaita**, que **no** lee temas de
`~/.local/share/themes`. La única vía real es un override de usuario:

```
~/.config/gtk-4.0/gtk.css
```

`gtk-4.0/gtk.css` está pensado justo para eso (archivo único, autocontenido).

**NO está aplicado.** Para probarlo:

```bash
# backup de lo que haya
cp -a ~/.config/gtk-4.0/gtk.css ~/.config/gtk-4.0/gtk.css.bak 2>/dev/null
# aplicar (symlink, no copia)
ln -sfn ~/Documents/canary/gtk-themes/atari-cx-40-imey/gtk-4.0/gtk.css ~/.config/gtk-4.0/gtk.css
```

Revertir: restaurar el `.bak`.

## Notas

- GTK4 se edita en `gtk-4.0/gtk.css` (colores con nombres libadwaita).
- El shell de GNOME es aparte (`gnome-shell/` + extensión User Themes).
