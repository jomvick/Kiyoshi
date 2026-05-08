# AppImage Build

## Requirements

```bash
# Installer les dépendances (Fedora)
sudo dnf install fuse libappindicator

# Installer appimagetool
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool

# Ou utiliser AppImageKit depuis AUR (Arch)
yay -S appimagekit
```

## Build

```bash
chmod +x build_appimage.sh
./build_appimage.sh
```

Cela crée: `Kiyoshi-1.0.0-linux-x86_64.AppImage`

## Usage

```bash
# Rendre exécutable
chmod +x Kiyoshi-1.0.0-linux-x86_64.AppImage

# Lancer
./Kiyoshi-1.0.0-linux-x86_64.AppImage

# Ou installer (Optionnel)
sudo cp Kiyoshi-1.0.0-linux-x86_64.AppImage /opt/kiyoshi.AppImage
sudo ln -s /opt/kiyoshi.AppImage /usr/local/bin/kiyoshi
kiyoshi
```

## Portable

L'AppImage est autonome et peut être:
- Lançée sans installation
- Copiée sur une clé USB
- Exécutée sur n'importe quelle distro compatible

## Troubleshoot

```bash
# Si erreurs de Fuse
sudo modprobe fuse

# Si problème de permissions
sudo chmod +x Kiyoshi-*.AppImage
```