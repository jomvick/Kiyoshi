#!/bin/bash
set -e

APP_VERSION="$(cat VERSION 2>/dev/null || echo "1.0.1")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Building Kiyoshi RPM v$APP_VERSION..."
echo ""

# Step 1: Build Flutter Linux release if not already built
if [ ! -f build/linux/x64/release/bundle/kiyoshi ]; then
    echo "==> Running build_runner..."
    dart run build_runner build --delete-conflicting-outputs
    echo ""
    echo "==> Building Flutter release..."
    flutter build linux --release
fi

# Step 2: Create RPM build tree
RPMBUILD_DIR="$SCRIPT_DIR/build/rpmbuild"
rm -rf "$RPMBUILD_DIR"
mkdir -p "$RPMBUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Step 3: Create source tarball (binary + libs + data)
TARBALL_DIR="$RPMBUILD_DIR/kiyoshi-$APP_VERSION"
mkdir -p "$TARBALL_DIR/lib"
cp build/linux/x64/release/bundle/kiyoshi "$TARBALL_DIR/"
cp build/linux/x64/release/bundle/lib/*.so "$TARBALL_DIR/lib/"
cp -r build/linux/x64/release/bundle/data "$TARBALL_DIR/"

cd "$RPMBUILD_DIR"
tar czf "SOURCES/kiyoshi-$APP_VERSION.tar.gz" "kiyoshi-$APP_VERSION/"
rm -rf "kiyoshi-$APP_VERSION"

# Step 4: Copy additional sources
cp "$SCRIPT_DIR/packaging/kiyoshi.sh" "$RPMBUILD_DIR/SOURCES/"
cp "$SCRIPT_DIR/packaging/kiyoshi.desktop" "$RPMBUILD_DIR/SOURCES/"
cp "$SCRIPT_DIR/packaging/kiyoshi.spec" "$RPMBUILD_DIR/SPECS/"

# Step 5: Build RPM (allow Flutter's build-path RPATHs in .so files)
echo "==> Building RPM..."
QA_RPATHS=$(( 0x0002 )) rpmbuild -bb \
    --define "_topdir $RPMBUILD_DIR" \
    "$RPMBUILD_DIR/SPECS/kiyoshi.spec"

# Step 6: Copy result
mkdir -p "$SCRIPT_DIR/build"
find "$RPMBUILD_DIR/RPMS" -name "*.rpm" -exec cp {} "$SCRIPT_DIR/build/" \;

echo ""
echo "✓ RPM package created!"
ls -lh "$SCRIPT_DIR/build/"*.rpm
