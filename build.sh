#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  배포용 빌드 스크립트 (Netlify 가 실행합니다)
#
#  하는 일: Flutter SDK 준비 → pub get → 웹 릴리즈 빌드(build/web)
#  ※ 내 PC 에서는 쓸 일이 없습니다. `flutter build web --release` 로 충분합니다.
#
#  Cloudflare Pages 로 옮기더라도 이 파일 그대로 씁니다
#  (빌드 명령 `bash build.sh`, 출력 폴더 `build/web`).
# ─────────────────────────────────────────────────────────────
set -euo pipefail

# 로컬 개발 버전과 맞춥니다. 바꿀 때는 netlify.toml 의 FLUTTER_VERSION 을 고치세요.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.8}"

# Netlify 는 빌드 사이에 /opt/build/cache 만 남겨둡니다.
# SDK 와 pub 패키지를 여기에 두면 두 번째 빌드부터 몇 분씩 아낍니다(무료 월 300분).
if [ -n "${NETLIFY:-}" ]; then
  CACHE_ROOT="${NETLIFY_BUILD_BASE:-/opt/build}/cache"
else
  CACHE_ROOT="${HOME}"
fi
mkdir -p "${CACHE_ROOT}"

FLUTTER_DIR="${CACHE_ROOT}/flutter"
STAMP="${FLUTTER_DIR}/.installed-version"
export PUB_CACHE="${CACHE_ROOT}/.pub-cache"
export PATH="${FLUTTER_DIR}/bin:${PATH}"

# 캐시에 남은 SDK 가 다른 버전이면 버리고 다시 받습니다.
if [ -x "${FLUTTER_DIR}/bin/flutter" ] && [ "$(cat "${STAMP}" 2>/dev/null || echo none)" != "${FLUTTER_VERSION}" ]; then
  echo "▶ 캐시된 SDK 버전이 달라 교체합니다"
  rm -rf "${FLUTTER_DIR}"
fi

if [ -x "${FLUTTER_DIR}/bin/flutter" ]; then
  echo "▶ 캐시된 Flutter ${FLUTTER_VERSION} 재사용"
else
  echo "▶ Flutter ${FLUTTER_VERSION} 내려받는 중…"
  TARBALL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  if curl -fsSL "${TARBALL}" | tar -xJ -C "${CACHE_ROOT}"; then
    echo "${FLUTTER_VERSION}" > "${STAMP}"
  else
    echo "▶ 공식 압축본을 못 받았습니다 → stable 채널에서 clone"
    rm -rf "${FLUTTER_DIR}"
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
    echo "${FLUTTER_VERSION}" > "${STAMP}"
  fi
fi

git config --global --add safe.directory "${FLUTTER_DIR}" 2>/dev/null || true

flutter --version
flutter pub get
flutter build web --release

echo "✅ build/web 생성 완료"
