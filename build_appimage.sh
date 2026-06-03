#!/bin/bash
set -e

# Export APPIMAGE_EXTRACT_AND_RUN=1 to run appimagetool in environments without FUSE (like Docker or CI)
export APPIMAGE_EXTRACT_AND_RUN=1

APPIMAGE_VERSION="$(cat VERSION 2>/dev/null || echo "1.0.1")"
ARCH="x86_64"

echo "==> Building Kiyoshi AppImage v$APPIMAGE_VERSION..."
echo ""

# Ensure Flutter build exists
if [ ! -f build/linux/x64/release/bundle/kiyoshi ]; then
    echo "==> Running build_runner for Drift code generation..."
    dart run build_runner build --delete-conflicting-outputs
    echo ""
    echo "==> Building Flutter release..."
    flutter build linux --release
fi

# Ensure appimagetool is available
if ! command -v appimagetool &> /dev/null; then
    echo "==> Downloading appimagetool..."
    wget -q "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -O /tmp/appimagetool
    chmod +x /tmp/appimagetool
    APPIMAGETOOL="/tmp/appimagetool"
else
    APPIMAGETOOL="appimagetool"
fi

# Create AppDir manually using appimagetool (more reliable and portable than appimage-builder)

# Create AppDir manually
echo "==> Creating AppDir..."
rm -rf kiyoshi.AppDir
mkdir -p kiyoshi.AppDir/usr/bin
mkdir -p kiyoshi.AppDir/usr/lib

cp -r build/linux/x64/release/bundle/* kiyoshi.AppDir/
cp AppRun kiyoshi.AppDir/AppRun
chmod +x kiyoshi.AppDir/AppRun

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

cp packaging/kiyoshi.png kiyoshi.AppDir/kiyoshi.png

echo "==> Packaging AppImage..."
$APPIMAGETOOL kiyoshi.AppDir "Kiyoshi-$APPIMAGE_VERSION-linux-$ARCH.AppImage"
rm -rf kiyoshi.AppDir
echo ""
echo "✓ Kiyoshi-$APPIMAGE_VERSION-linux-$ARCH.AppImage created!"
