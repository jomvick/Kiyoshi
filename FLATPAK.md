# Flatpak Build

## Build

```bash
# Installer flatpak-builder si pas encore fait
sudo dnf install flatpak-builder

# Construire le flatpak
flatpak-builder --user --install build.flatpak io.zenstudio.kiyoshi.yml

# Ou construire le fichier .flatpak
flatpak-builder --force-clean build.flatpak io.zenstudio.kiyoshi.yml
```

## Install

```bash
flatpak install kiyoshi.flatpak
```

## Publishing to Flathub

1. Fork https://github.com/flathub/io.zenstudio.kiyoshi
2. Ajouter le build à votre repo
3. Pull request vers Flathub

## Dependencies

- org.freedesktop.Platform 23.08
- org.freedesktop.Sdk

## Permissions

- `--share=ipc` - IPC pour le rendu
- `--socket=fallback-x11` - X11 si Wayland non disponible
- `--socket=wayland` - Wayland
- `--device=dri` - Accélération GPU
- `--share=network` - Réseau (pour les métadonnées URL)
- `--filesystem=home` - Accès aux fichiers locales