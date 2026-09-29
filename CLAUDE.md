# CLAUDE.md — 이 저장소에서 작업할 때 읽을 것

Claude Code 가 이 저장소를 열면 이 파일을 자동으로 읽습니다. 사람이 읽어도 됩니다.
앱 소개·폴더 구조는 [README.md](README.md), 배포 연결 절차는 팀원에게 받은 `06_공유배포가이드.md` 를 보세요.

---

## 1. 이 앱이 무엇인가

할렐루야교회 청년1부 **뉴웨이브 사랑방(약 20명)** 전용 Flutter Web 앱. 2026-08-30 착수.

카톡 대화 로그를 분석해서 시작한 프로젝트라, 설계 원칙이 하나 있습니다.

> **"카톡에서 흘러가면 안 되는 것만 담는다."**
> 잡담은 계속 카톡에서, 남아야 하는 기록만 앱에서.

**킬러 기능은 기도제목 카톡 복사** ([lib/features/prayer/kakao_format.dart](lib/features/prayer/kakao_format.dart)).
사랑방장이 매주 20명분 기도제목을 손으로 타이핑하던 걸 버튼 하나로 바꾸는 것이고, 사람들이 이 앱을 쓰는 이유의 대부분입니다. **이 기능의 출력 포맷을 바꿀 때는 특히 조심하세요** — 카톡에 그대로 붙여넣는 텍스트라 줄바꿈 하나가 의미가 있고, "나만 보기" 항목은 절대 포함되면 안 됩니다.

**기능을 추가하기 전에 물어볼 것:** "이게 카톡에서 흘러가면 아까운 것인가?"
아니라면 넣지 않는 편이 낫습니다. 기능 수보다 매주 실제로 쓰이느냐가 중요합니다.

---

## 2. 빠른 시작

```bash
flutter pub get
flutter run -d chrome      # 개발
flutter test               # 테스트 (주차 계산)
flutter analyze            # 커밋 전 확인
flutter build web --release
```

**Flutter 3.44.8 / Dart 3.12.2** 기준입니다. 버전이 다르면 [netlify.toml](netlify.toml) 의 `FLUTTER_VERSION` 과 맞추세요 (빌드 환경이 그 버전을 씁니다).

주요 의존성: `firebase_core` `firebase_auth` `cloud_firestore` `flutter_riverpod` `go_router` `image_picker` `cached_network_image` `url_launcher` `intl`

---

## 3. 배포 — main 에 push 하면 자동입니다 ⚠️

```
git push (main)  →  Netlify 가 build.sh 실행  →  2~3분 뒤 사이트 반영
```

- 빌드 스크립트는 [build.sh](build.sh), 설정은 [netlify.toml](netlify.toml). 출력은 `build/web`.
- **무료 빌드 시간이 월 300분**입니다. 문서만 고친 커밋은 메시지에 `[skip ci]` 를 넣으면 빌드를 건너뜁니다.
- `main` 에 push 하는 순간 **사랑방 멤버 20명이 쓰는 앱이 바뀝니다.** 실험은 다른 브랜치에서 하세요.

**push 해도 반영되지 않는 것 — 착각하기 쉬움**

| 고친 것 | 반영 방법 |
|---|---|
| `firestore.rules` | Firebase 콘솔 → Firestore → 규칙에 붙여넣고 **게시** (저장소 파일은 사본일 뿐) |
| Firebase 설정 (승인 도메인, 로그인 방식) | Firebase 콘솔에서만 |
| Cloudinary 프리셋 | Cloudinary 대시보드에서만 |
| 새 배포 주소 | 승인된 도메인에 추가하지 않으면 **구글 로그인이 안 됩니다** |

---

## 4. 코드 지도

```
lib/
├─ app_config.dart      ⚙️ 설정값이 있는 유일한 파일 (Firebase 5개 + Cloudinary 2개 + 사랑방 목록)
├─ main.dart            진입점. 설정이 비었으면 안내 화면을 띄웁니다
├─ theme.dart           디자인 토큰 — AppColors / AppRadius / AppShadow / AppText
├─ router.dart          go_router. 5탭 + 하위 라우트
├─ shell.dart           탭 셸, 프로필 게이트, SubPage 공통 골격
│
├─ core/
│  ├─ week.dart         주차 계산 (일요일 시작) → id "2026-W35", mmdd "0830"
│  ├─ refs.dart         Firestore 경로 모음 — 경로는 반드시 여기를 거칩니다
│  ├─ providers.dart    Riverpod 프로바이더 (인증/멤버/기도/모임/…)
│  └─ cloudinary.dart   Unsigned 업로드 + 썸네일/원본 URL 조립
│
├─ models/models.dart   Member, PrayerEntry, Meeting, Album, Poll, Settlement, …
├─ widgets/common.dart  공용 위젯 (아래 6장 참고)
└─ features/            화면 — auth / home / prayer / chat / meeting / album / more
```

**라우트:** `/login` `/home` `/prayer` `/chat` `/meetings` `/more`
`/more` 아래에 `albums` `notices` `notes` `members` `polls` `settlements` `profile` `admin`

---

## 5. 데이터 모델 (Firestore)

경로는 전부 [lib/core/refs.dart](lib/core/refs.dart) 에 있습니다. **직접 문자열로 경로를 쓰지 말고 `Refs` 를 쓰세요.**

```
groups/nw2026                          ← 청년부 1개 고정. 그룹 선택 UI 없음
 ├ members/{uid}                       프로필은 청년부 전체에서 하나 (roomId 로 분반 표시)
 │   └ birthdayCards/{year}/messages   생일 롤링페이퍼
 └ rooms/{roomId}                      hj(희진) / pg(평강) / all(전체)
     ├ weeks/{weekId}/prayers/{uid}         기도제목 — 분반 사랑방에만, 전체 사랑방엔 없음
     │    └ private/items                   ⭐ "나만 보기" — 규칙상 본인 외 아무도 못 읽음
     ├ prayerReactions/{weekId__uid__n__나}  🙏 기도했어요
     ├ routineLogs/{uid}_{YYYY-MM-DD}       신앙루틴 체크
     ├ messages                             채팅
     ├ meetings/{id}/attendance/{uid}       모임·출석
     ├ albums/{id}/photos/{id}              앨범 (이미지 실물은 Cloudinary)
     └ notices · polls · settlements · sermonNotes
```

**설계 의도 — 고치기 전에 알아야 할 것**

- **"나만 보기"는 화면이 아니라 경로와 규칙으로 막습니다.** 공개 항목은 `prayers/{uid}`, 비공개는 그 하위 `private/items`. UI 에서 거르는 방식으로 바꾸지 마세요.
- **🙏 반응이 별도 컬렉션인 이유:** 기도제목 문서는 본인만 쓸 수 있어야 해서, 남이 누르는 반응을 같은 문서에 넣을 수 없습니다. 문서 ID 를 `{weekId}__{대상uid}__{항목번호}__{내uid}` 로 조합해 중복을 막습니다.
- **복합 인덱스가 필요 없게 짜여 있습니다.** 연속 일수는 `routineLogs` 의 문서 ID 범위 쿼리로 계산합니다. 새 쿼리를 추가할 때 이 성질을 깨면 Firebase 콘솔에서 인덱스를 만들어야 하니, 가능하면 문서 ID 설계로 푸세요.
- **주차는 일요일 시작입니다.** 카톡에 올리던 `0104 기도제목 및 신앙루틴` 의 `0104` 가 그 주 주일 날짜라서입니다. [test/week_test.dart](test/week_test.dart) 가 이걸 지킵니다.
- **사진은 Firebase Storage 가 아니라 Cloudinary** 입니다 (Storage 는 카드 등록이 필요해서). Unsigned 업로드 프리셋 2종.

---

## 6. 코드 관습 — 지켜주세요

- **설정값은 `app_config.dart` 한 곳에만.** 다른 파일에 Firebase/Cloudinary 값을 흩뿌리지 않습니다.
- **색·글자·그림자·모서리는 `theme.dart` 토큰만 씁니다.** 화면 파일에 raw `TextStyle(...)` 이나 `Color(0xFF...)` 를 새로 만들지 마세요. 필요하면 토큰을 추가합니다.
- **공용 위젯을 먼저 찾습니다** ([lib/widgets/common.dart](lib/widgets/common.dart)):
  `SoftCard` `Avatar` `EmptyState` `Skeleton` `ListSkeleton` `Pill` `Meter` `KV` `SectionTitle` `Bounded` `SheetHandle` `Loading` `ErrorNote`
- **UI 완성도는 "시중 앱 수준"이 기본값입니다.** 이 앱은 20명이 매주 쓰는 앱이라 투박하면 아무도 안 씁니다. 구체적으로:
  - 로딩은 스피너 대신 **스켈레톤**
  - 테두리보다 **옅은 이중 그림자** (`AppShadow`)
  - 빈 목록에도 **EmptyState 안내 문구**를 반드시
  - 한글 자간은 **-0.2 ~ -0.5** (`AppText` 에 반영돼 있음)
- 기능을 만들고 끝내지 말고 **디자인 다듬기 패스를 한 번 더** 도세요.
- 커밋 메시지는 한국어로, **무엇을 왜 고쳤는지** 씁니다.

---

## 7. 건드리면 안 되는 것

| 하지 말 것 | 이유 |
|---|---|
| `AppConfig.rooms` 의 `id` (`hj` `pg` `all`) 변경 | **Firestore 경로입니다.** 바꾸면 기존 기록이 전부 안 보입니다. 이름(`name`)만 바꾸세요 |
| `groups/nw2026` 경로 변경 | 위와 같음 |
| `netlify.toml` 에 `Cross-Origin-Opener-Policy` 추가 | 구글 로그인 팝업(`signInWithPopup`)이 막혀 로그인이 통째로 죽습니다 |
| `_redirects` / redirects 규칙 삭제 | SPA 라우팅이 깨져 새로고침하면 404 |
| `build.sh` 를 CRLF 로 저장 | 리눅스 빌드가 `$'\r': command not found` 로 실패. `.gitattributes` 가 막고 있습니다 |
| **비밀값 커밋** | 이 저장소는 **공개(Public)** 입니다. 서비스 계정 JSON·토큰·비밀번호는 절대 커밋하지 마세요. 배포용 비밀값은 Netlify 환경변수에만 (`FIREBASE_SERVICE_ACCOUNT`) |
| 개인정보 파일 커밋 | 카톡 원본 로그(`사랑방 톡 내용.txt`) 등은 **일부러 저장소 밖**에 둡니다. 실명 대화라 올리면 안 됩니다 |
| `firestore.rules` 를 고치고 "반영됐다"고 보고 | 콘솔에서 게시해야 실제로 적용됩니다 |

---

## 8. 현재 상태와 남은 일 (2026-09-11)

- ✅ 앱 구현 완료, `flutter build web --release` 성공
- ✅ GitHub 비공개 저장소 + 자동 배포 설정(`build.sh` / `netlify.toml`)
- ⬜ Netlify ↔ GitHub 연결 (저장소 주인이 대시보드에서)
- ⬜ Firebase Authentication → 승인된 도메인에 배포 주소 추가 ⚠️
- ⬜ 첫 로그인 후 `groups/nw2026` 에 `leaderUid` 넣기 (관리자 메뉴가 이걸로 열립니다)

**보안 — 2026-09-29 에 한 번 조였습니다.**
공지·투표·정산·사진의 `update` 가 예전에는 `signedIn()` 만 요구해서, 로그인한 사람이면 남의 공지 본문이나 정산 금액까지 덮어쓸 수 있었습니다. 지금은 `onlyFields()` 헬퍼로 **작성자는 전부, 남은 정해진 필드만** 바꿀 수 있습니다 (공지 `readBy`, 투표 `options`, 정산 `paid`, 사진 `likes`·`hidden`).
⚠️ **규칙을 고쳤으면 Firebase 콘솔에 붙여넣고 게시해야 실제로 적용됩니다.** 파일만 고치고 "막았다"고 생각하지 마세요.

참고로 이 앱은 **승인 절차가 없습니다** (구글 로그인 = 멤버). 외부인을 막으려면 `groups/nw2026` 문서의 `joinCode` 필드에 초대코드를 넣으면 로그인 시 코드를 묻습니다 ([login_page.dart:60](lib/features/auth/login_page.dart:60)).

---

## 9. 둘이서 작업하는 법

```bash
git pull                                  # 항상 먼저
# ... 수정 ...
flutter analyze && flutter test
git add -A && git commit -m "무엇을 왜 고쳤는지"
git push
```

- **push 전에 `git pull`.** 안 그러면 서로 덮어씁니다.
- 같은 화면을 크게 뜯는 작업은 **시작 전에 상대에게 알립니다.**
- 사랑방 멤버가 앱을 쓰는 시간(주일 저녁)에는 배포를 피합니다.
