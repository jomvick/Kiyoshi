#!/bin/bash
# Build AppImage script
# Usage: ./build_appimage.sh

set -e

APPIMAGE_VERSION="1.0.0"
ARCH="x86_64"

echo "Building Kiyoshi AppImage v$APPIMAGE_VERSION..."

# Créer la structure AppDir
mkdir -p kiyoshi.AppDir/usr/bin
mkdir -p kiyoshi.AppDir/usr/lib
mkdir -p kiyoshi.AppDir/usr/share/applications
mkdir -p kiyoshi.AppDir/usr/share/icons/hicolor/256x256/apps

# Copier le bundle
cp -r build/linux/x64/release/bundle/* kiyoshi.AppDir/

# Copier AppRun comme usr/bin/kiyoshi
#(On garde le bundle original qui contient déjà le binaire)
cp AppRun kiyoshi.AppDir/AppRun
chmod +x kiyoshi.AppDir/AppRun

# Créer le .desktop
cat > kiyoshi.AppDir/kiyoshi.desktop << 'EOF'
[Desktop Entry]
Name=Kiyoshi
Comment=Zen Studio - Glassmorphic Kanban App
Exec=kiyoshi
Icon=kiyoshi
Terminal=false
Type=Application
Categories=Office;ProjectManagement;
Keywords=kanban;notes;productivity;zen;
StartupNotify=true
EOF

cp kiyoshi.desktop kiyoshi.AppDir/usr/share/applications/

# Copier l'icône (si elle existe)
if [ -f linux/flutter/ephemeral/.cmake/icon.png ]; then
    cp linux/flutter/ephemeral/.cmake/icon.png kiyoshi.AppDir/kiyoshi.png
    cp kiyoshi.AppDir/kiyoshi.png kiyoshi.AppDir/usr/share/icons/hicolor/256x256/apps/
fi

echo "Structure AppDir créée."

# Vérifier appimagetool
if command -v appimagetool &> /dev/null; then
    echo "Génération de l'AppImage..."
    appimagetool kiyoshi.AppDir Kiyoshi-$APPIMAGE_VERSION-linux-$ARCH.AppImage
    rm -rf kiyoshi.AppDir
    echo "✓ Kiyoshi-$APPIMAGE_VERSION-linux-$ARCH.AppImage créé!"
else
    echo "⚠ appimagetool non trouvé."
    echo "Installez AppImageTool:"
    echo "  wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    echo "  chmod +x appimagetool-x86_64.AppImage"
    echo "  sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool"
    echo ""
    echo "Puis lancez: appimagetool kiyoshi.AppDir Kiyoshi-$APPIMAGE_VERSION-linux-$ARCH.AppImage"
fi