#!/bin/bash
set -euo pipefail

FLUTTER_VERSION="3.29.2"
FLUTTER_ROOT="${HOME}/flutter"

if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -d "${FLUTTER_ROOT}" ]; then
    git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git "${FLUTTER_ROOT}"
  fi
  export PATH="${FLUTTER_ROOT}/bin:${PATH}"
fi

flutter config --enable-web
flutter pub get
flutter build web --release
