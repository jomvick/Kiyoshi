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

# Ensure appimagetool is available
if ! command -v appimagetool &> /dev/null; then
    echo "==> Downloading appimagetool..."
    wget -q "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -O /tmp/appimagetool
    chmod +x /tmp/appimagetool
    APPIMAGETOOL="/tmp/appimagetool"
else
    APPIMAGETOOL="appimagetool"
fi

# Try appimage-builder first (requires dpkg-deb for Debian-based deps)
if command -v appimage-builder &> /dev/null && command -v dpkg-deb &> /dev/null; then
    echo "==> Using appimage-builder..."
    appimage-builder --recipe AppImageBuilder.yml
    echo ""
    echo "✓ AppImage created!"
    exit 0
fi

if command -v appimage-builder &> /dev/null && ! command -v dpkg-deb &> /dev/null; then
    echo "==> dpkg-deb not found. appimage-builder needs it for Debian deps."
    echo "  Attempting to install dpkg..."
    DOWNLOAD_OK=false
    if command -v dnf &> /dev/null; then
        dnf download dpkg --destdir=/tmp 2>/dev/null && DOWNLOAD_OK=true
    fi
    if [ "$DOWNLOAD_OK" = true ]; then
        rpm -i --nodeps /tmp/dpkg-*.rpm 2>/dev/null && echo "  dpkg installed successfully." && appimage-builder --recipe AppImageBuilder.yml && echo "" && echo "✓ AppImage created!" && exit 0
    fi
    echo "  Could not install dpkg. Falling back to appimagetool method."
fi

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

cp assets/icons/kiyoshi.png kiyoshi.AppDir/kiyoshi.png

<<<<<<< HEAD
echo "==> Packaging AppImage..."
$APPIMAGETOOL kiyoshi.AppDir "Kiyoshi-$APPIMAGE_VERSION-linux-$ARCH.AppImage"
rm -rf kiyoshi.AppDir
echo ""
echo "✓ Kiyoshi-$APPIMAGE_VERSION-linux-$ARCH.AppImage created!"
=======
    cp packaging/kiyoshi.png kiyoshi.AppDir/kiyoshi.png
    cp packaging/kiyoshi.png kiyoshi.AppDir/usr/share/icons/hicolor/256x256/apps/

    appimagetool kiyoshi.AppDir "Kiyoshi-$APPIMAGE_VERSION-linux-$ARCH.AppImage"
    rm -rf kiyoshi.AppDir
    echo ""
    echo "✓ Kiyoshi-$APPIMAGE_VERSION-linux-$ARCH.AppImage created!"
}

# Prefer appimage-builder (recommended)
if command -v appimage-builder &> /dev/null; then
    if ! command -v dpkg-deb &> /dev/null; then
        echo "==> dpkg-deb not found. Installing dpkg (needed by appimage-builder)..."
        if command -v dnf &> /dev/null; then
            sudo dnf install -y dpkg
        elif command -v apt &> /dev/null; then
            sudo apt install -y dpkg
        elif command -v yum &> /dev/null; then
            sudo yum install -y dpkg
        else
            echo "⚠ Could not install dpkg automatically."
            echo "  Install it manually: sudo dnf install dpkg"
            appimagetool_fallback
            exit $?
        fi
    fi
    echo "==> Using appimage-builder (recommended method)"
    appimage-builder --recipe AppImageBuilder.yml
    echo ""
    echo "✓ AppImage created!"
    exit 0
fi

appimagetool_fallback
>>>>>>> 5c65b05d389a5e3d0e64d4e951db1419fe5edbcf
