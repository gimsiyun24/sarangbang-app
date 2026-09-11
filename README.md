# 사랑방 나눔 🍀

> 할렐루야교회 청년1부 뉴웨이브 사랑방 (2026) 전용 웹앱
> **"우리 사랑방의 1년이 남는 곳"**

카톡은 흘러가는 매체인데 사랑방 활동은 쌓여야 하는 것들입니다.
이 앱은 카톡을 대체하지 않고, **카톡에서 흘러가면 안 되는 것만 담는 그릇**입니다.

---

## 시작하기

1. `lib/app_config.dart` 에 Firebase 값 5개 + Cloudinary 값 2개를 채웁니다
2. `flutter run -d chrome`

자세한 건 상위 폴더의 **`04_앱실행가이드.md`** 를 보세요.
값을 안 채우고 실행하면 앱이 무엇을 채워야 하는지 안내 화면을 띄웁니다.

---

## 폴더 구조

```
lib/
├─ app_config.dart          ⚙️ 사용자가 값을 채우는 유일한 파일
├─ main.dart                진입점 + 설정 안내 화면
├─ theme.dart               디자인 토큰 (색/그림자/타이포/라운드)
├─ router.dart              go_router — 5탭 + 하위 라우트
├─ shell.dart               탭 셸, 프로필 게이트, SubPage 공통 골격
│
├─ core/
│  ├─ week.dart             주일(일요일) 기준 주차 계산 → "2026-W35", "0830"
│  ├─ refs.dart             Firestore 경로 모음
│  ├─ providers.dart        Riverpod 프로바이더 (인증/멤버/기도/모임/…)
│  └─ cloudinary.dart       Unsigned 업로드 + 썸네일/원본 URL 조립
│
├─ models/models.dart       Member, PrayerEntry, Meeting, Album, Poll, …
├─ widgets/common.dart      SoftCard, Avatar, Pill, Meter, Skeleton, 시트 …
│
└─ features/
   ├─ auth/                 로그인, 첫 프로필 설정
   ├─ home/                 홈 (D-day·생일·루틴 체크·공지·사진)
   ├─ prayer/               ★ 기도제목/신앙루틴 + 카톡 복사 + 응답 아카이브
   ├─ meeting/              모임 일정 · 출석 · 통계
   ├─ album/                앨범 · 업로드 · 뷰어
   └─ more/                 공지 · 말씀노트 · 투표 · 정산 · 멤버/생일 · 프로필 · 관리자

firestore.rules             보안 규칙 (콘솔에 붙여넣을 내용)
netlify.toml, web/_redirects  배포 설정
test/week_test.dart         주차 계산 테스트
```

---

## 설계 메모

**주차 = 주일 시작.** 카톡에 올리던 `0104 기도제목 및 신앙루틴` 의 `0104` 가 그 주 주일 날짜라서,
`Week` 클래스는 일요일을 주의 시작으로 잡습니다. `2026-08-30` → `2026-W35`, 머리말 `0830`.

**"나만 보기"는 화면이 아니라 규칙에서 막습니다.**
공개 항목은 `weeks/{w}/prayers/{uid}`, 비공개 항목은 `weeks/{w}/prayers/{uid}/private/items`
에 따로 저장합니다. 후자는 보안 규칙상 본인만 읽을 수 있고, 카톡 복사에도 포함되지 않습니다.

**🙏 기도했어요는 별도 컬렉션.**
기도제목 문서는 본인만 쓸 수 있어야 하므로, 남이 누르는 반응은
`prayerReactions/{weekId}__{대상uid}__{항목번호}__{내uid}` 문서로 분리했습니다.

**복합 인덱스가 필요 없게 짰습니다.**
연속 일수는 `routineLogs` 문서 ID(`{uid}_{YYYY-MM-DD}`) 범위 쿼리로 계산합니다.
따라서 Firestore 콘솔에서 인덱스를 따로 만들 필요가 없습니다.

**사랑방은 하나.** `groups/nw2026` 로 고정이고 그룹 선택 UI가 없습니다.
방장 권한은 그 문서의 `leaderUid` / `admins` 로 결정합니다.

---

## 명령어

```bash
flutter run -d chrome
```

```bash
flutter test
```

```bash
flutter build web --release
```

---

## 함께 개발하기

저장소는 GitHub(비공개), 배포는 Netlify 입니다.
Claude Code 같은 AI 도구로 작업한다면 **[CLAUDE.md](CLAUDE.md)** 를 먼저 보세요 — 구조·관습·주의사항이 거기 정리돼 있고, Claude Code 는 이 파일을 자동으로 읽습니다.
**`main` 에 push 하면 2~5분 뒤 사이트에 자동 반영**됩니다. 따로 올릴 파일은 없습니다.

```bash
git clone <저장소 주소>
cd sarangbang_app
flutter pub get
flutter run -d chrome
```

고친 다음에는

```bash
git pull                              # 먼저 상대가 고친 걸 받아옵니다
git add -A && git commit -m "무엇을 고쳤는지"
git push                              # → Netlify 가 알아서 빌드·배포
```

**알아둘 것**

- Flutter **3.44.8** (Dart 3.12.2) 기준입니다. 빌드 버전은 `netlify.toml` 의 `FLUTTER_VERSION` 에 있고, 내 PC 버전과 맞춰두는 게 좋습니다.
- 설정값은 `lib/app_config.dart` 한 파일에만 있습니다. 거기 Firebase·Cloudinary 값은 브라우저에 노출돼도 되는 값이고, 실제 보안은 `firestore.rules` 가 담당합니다.
- **`firestore.rules` 는 push 해도 반영되지 않습니다.** 고쳤으면 Firebase 콘솔 → Firestore → 규칙에 붙여넣고 "게시"를 눌러야 합니다.
- 배포 주소를 새로 만들면 **Firebase Authentication → Settings → 승인된 도메인**에 그 주소를 추가해야 구글 로그인이 됩니다.
- 같은 파일을 동시에 고치면 충돌합니다. 큰 작업은 시작 전에 서로 알려주세요.
