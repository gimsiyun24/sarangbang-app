"""Pretendard 를 한글 상용 영역만 남기고 줄입니다.

Flutter 는 pubspec 에 선언된 폰트를 앱 시작 때 **전부** 내려받습니다.
한글 완성형 11,172자는 전부 남깁니다(채팅에 어떤 글자가 올지 모르므로).
힌팅/불필요 테이블만 걷어내 종당 1.5MB -> 1.25MB 로 줄입니다.
굵기는 Regular(400)/Bold(700) 2종만 씁니다. Flutter 가 w500~w800 을
가까운 굵기로 알아서 매핑하므로 화면은 거의 그대로이면서 용량이 절반입니다.

    python tool/subset_fonts.py

원본은 assets/fonts/_original/ 에 보관합니다. 되돌리려면 그 폴더에서 복사하세요.
"""

import os
import shutil
import sys

try:
    from fontTools import subset
except ImportError:
    sys.exit("fonttools 가 필요합니다:  pip install fonttools brotli")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_DIR = os.path.join(ROOT, "assets", "fonts")
BACKUP_DIR = os.path.join(FONT_DIR, "_original")

WEIGHTS = ["Regular", "Bold"]

# 남길 문자 범위
UNICODES = ",".join([
    "U+0020-007E",    # 기본 라틴 (영문/숫자/기호)
    "U+00A0-00FF",    # 라틴 보충
    "U+2000-206F",    # 일반 구두점 (… – — ‘ ’ “ ” 등)
    "U+20A9",         # 원화 ₩
    "U+2190-21FF",    # 화살표 (→ ← ↑ ↓)
    "U+2500-257F",    # 괘선 (─ │ 등)
    "U+25A0-25FF",    # 기하 도형 (■ ● ▲)
    "U+3000-303F",    # CJK 구두점
    "U+3131-318E",    # 한글 자모 (ㄱㄴㄷ ㅋㅋㅋ)
    "U+AC00-D7A3",    # 한글 완성형 전체 11,172자
    "U+FF00-FFEF",    # 전각 영숫자
])


def main():
    if not os.path.isdir(FONT_DIR):
        sys.exit("assets/fonts 폴더가 없습니다.")

    os.makedirs(BACKUP_DIR, exist_ok=True)
    total_before = total_after = 0

    for w in WEIGHTS:
        name = "Pretendard-%s.otf" % w
        path = os.path.join(FONT_DIR, name)
        backup = os.path.join(BACKUP_DIR, name)

        if not os.path.exists(path):
            print("  건너뜀 (파일 없음): %s" % name)
            continue

        # 원본을 아직 백업 안 했으면 백업 (두 번 돌려도 안전하도록)
        if not os.path.exists(backup):
            shutil.copy2(path, backup)

        before = os.path.getsize(backup)
        out = os.path.join(FONT_DIR, name + ".tmp")

        subset.main([
            backup,
            "--unicodes=%s" % UNICODES,
            "--layout-features=*",
            "--no-hinting",
            "--output-file=%s" % out,
        ])

        os.replace(out, path)
        after = os.path.getsize(path)
        total_before += before
        total_after += after
        print("  %-12s %6.0f KB -> %5.0f KB  (%.0f%% 감소)"
              % (w, before / 1024, after / 1024, (1 - after / before) * 100))

    if total_before:
        print("\n합계 %.1f MB -> %.1f MB  (%.0f%% 감소)"
              % (total_before / 1048576, total_after / 1048576,
                 (1 - total_after / total_before) * 100))
        print("원본 보관: assets/fonts/_original/")


if __name__ == "__main__":
    main()
