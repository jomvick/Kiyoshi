#!/bin/bash
set -e

APPIMAGE_VERSION="$(cat VERSION 2>/dev/null || echo "1.0.0")"
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

# Prefer appimage-builder (recommended)
if command -v appimage-builder &> /dev/null; then
    echo "==> Using appimage-builder (recommended method)"
    appimage-builder --recipe AppImageBuilder.yml
    echo ""
    echo "✓ AppImage created!"
    exit 0
fi

# Fallback: manual appimagetool method
echo "==> appimage-builder not found, falling back to appimagetool..."

if ! command -v appimagetool &> /dev/null; then
    echo "ERROR: Neither appimage-builder nor appimagetool found."
    echo ""
    echo "Install appimage-builder (recommended):"
    echo "  pip3 install appimage-builder"
    echo ""
    echo "Or install appimagetool:"
    echo "  wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
    echo "  chmod +x appimagetool-x86_64.AppImage"
    echo "  sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool"
    exit 1
fi

# Manual AppDir structure
rm -rf kiyoshi.AppDir
mkdir -p kiyoshi.AppDir/usr/bin
mkdir -p kiyoshi.AppDir/usr/lib
mkdir -p kiyoshi.AppDir/usr/share/applications
mkdir -p kiyoshi.AppDir/usr/share/icons/hicolor/256x256/apps

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

cp kiyoshi.AppDir/kiyoshi.desktop kiyoshi.AppDir/usr/share/applications/

# Create a minimal icon if none exists
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x0aIDATx\x9cc\x00\x00\x00\x02\x00\x01\xe7\xa3\x26\x37\x00\x00\x00\x00IEND\xae\x42\x60\x82' > kiyoshi.AppDir/kiyoshi.png
cp kiyoshi.AppDir/kiyoshi.png kiyoshi.AppDir/usr/share/icons/hicolor/256x256/apps/

appimagetool kiyoshi.AppDir "Kiyoshi-$APPIMAGE_VERSION-linux-$ARCH.AppImage"
rm -rf kiyoshi.AppDir

echo ""
echo "✓ Kiyoshi-$APPIMAGE_VERSION-linux-$ARCH.AppImage created!"
