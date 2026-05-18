#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

echo "==> Installing dependencies"
bash install_dependency.sh

echo "==> Adding build info"
cd ClashFX
python3 add_build_info.py
cd ..

echo "==> Building ClashFX"
xcodebuild clean build \
  -workspace ClashFX.xcworkspace \
  -scheme ClashFX \
  -configuration Release \
  -derivedDataPath ./build_derived_data \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  ENABLE_HARDENED_RUNTIME=NO

echo "==> Copying ClashFX.app"
APP_PATH=$(find ./build_derived_data/Build/Products/Release -name "ClashFX.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
  echo "Error: ClashFX.app not found in derived data"
  exit 1
fi

rm -rf ./ClashFX.app
cp -R "$APP_PATH" ./ClashFX.app

echo "==> Cleaning up derived data"
rm -rf ./build_derived_data

echo ""
echo "Done! App is at: $PROJECT_ROOT/ClashFX.app"
