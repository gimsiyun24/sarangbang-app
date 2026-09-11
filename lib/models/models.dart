import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_config.dart';

DateTime? _dt(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return null;
}

List<String> _strs(dynamic v) =>
    (v as List?)?.map((e) => e.toString()).toList() ?? const [];

// ─────────────────────────────────────────── 멤버
class Member {
  final String uid, name, nickname, photoUrl, bio, birthday; // birthday: "MM-DD"

  /// 이 사람이 속한 **분반 사랑방** id (hj / pg). 전체 사랑방은 모두 자동 소속.
  final String roomId;

  final DateTime? joinedAt, lastSeenAt;

  /// 알림함을 마지막으로 연 시각 — 제목 줄 종의 빨간 점 기준 (core/inbox.dart)
  final DateTime? noticesSeenAt;

  Member({
    required this.uid,
    required this.name,
    this.nickname = '',
    this.photoUrl = '',
    this.bio = '',
    this.birthday = '',
    this.roomId = '',
    this.joinedAt,
    this.lastSeenAt,
    this.noticesSeenAt,
  });

  factory Member.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Member(
      uid: d.id,
      name: (m['name'] ?? '') as String,
      nickname: (m['nickname'] ?? '') as String,
      photoUrl: (m['photoUrl'] ?? '') as String,
      bio: (m['bio'] ?? '') as String,
      birthday: (m['birthday'] ?? '') as String,
      roomId: (m['roomId'] ?? '') as String,
      joinedAt: _dt(m['joinedAt']),
      lastSeenAt: _dt(m['lastSeenAt']),
      noticesSeenAt: _dt(m['noticesSeenAt']),
    );
  }

  /// 분반이 정해져야 앱을 쓸 수 있습니다.
  bool get hasRoom => AppConfig.classRooms.any((r) => r.id == roomId);

  /// 화면에 쓰는 이름 (설정에 따라 별칭 우선)
  String get display {
    if (AppConfig.preferNickname) {
      return nickname.isNotEmpty ? nickname : (name.isNotEmpty ? name : '이름없음');
    }
    return name.isNotEmpty ? name : (nickname.isNotEmpty ? nickname : '이름없음');
  }

  /// 카톡 복사에 쓰는 짧은 이름 (별칭 > 실명 끝 두 글자: 홍혜원 → 혜원)
  String get shortName {
    if (nickname.isNotEmpty) return nickname;
    if (name.length >= 3) return name.substring(1);
    return name;
  }

  String get initial => display.isNotEmpty ? display.substring(0, 1) : '?';
  bool get isProfileComplete => name.trim().isNotEmpty;

  int? get birthMonth {
    final p = birthday.split('-');
    return p.length == 2 ? int.tryParse(p[0]) : null;
  }

  int? get birthDay {
    final p = birthday.split('-');
    return p.length == 2 ? int.tryParse(p[1]) : null;
  }

  /// 지정 연도의 생일 (birthday 없으면 null)
  DateTime? birthdayIn([int? year]) {
    final mm = birthMonth, dd = birthDay;
    if (mm == null || dd == null) return null;
    return DateTime(year ?? DateTime.now().year, mm, dd);
  }

  /// 오늘로부터 다음 생일까지 남은 일수
  int? get daysToBirthday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var b = birthdayIn(now.year);
    if (b == null) return null;
    if (b.isBefore(today)) b = birthdayIn(now.year + 1)!;
    return b.difference(today).inDays;
  }
}

// ─────────────────────────────────────────── 기도제목
enum Vis { all, private }

class PrayerTopic {
  final String text;
  final Vis visibility;
  final List<String> prayedBy;

  PrayerTopic({
    required this.text,
    this.visibility = Vis.all,
    this.prayedBy = const [],
  });

  bool get isPrivate => visibility == Vis.private;

  Map<String, dynamic> toMap() => {
        'text': text,
        'visibility': visibility.name,
        'prayedBy': prayedBy,
      };

  factory PrayerTopic.fromMap(Map<String, dynamic> m) => PrayerTopic(
        text: (m['text'] ?? '') as String,
        visibility: (m['visibility'] == 'private') ? Vis.private : Vis.all,
        prayedBy: _strs(m['prayedBy']),
      );

  PrayerTopic copyWith({
    String? text,
    Vis? visibility,
    List<String>? prayedBy,
  }) =>
      PrayerTopic(
        text: text ?? this.text,
        visibility: visibility ?? this.visibility,
        prayedBy: prayedBy ?? this.prayedBy,
      );
}

// ─────────────────────────────────────────── 채팅
class ChatMessage {
  final String id, uid, text;
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.uid,
    required this.text,
    this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return ChatMessage(
      id: d.id,
      uid: (m['uid'] ?? '') as String,
      text: (m['text'] ?? '') as String,
      createdAt: _dt(m['createdAt']),
    );
  }
}

/// 한 사람의 한 주치 기도제목 + 신앙루틴
class PrayerEntry {
  final String uid;
  final List<PrayerTopic> topics; // 공개 항목
  final List<PrayerTopic> private; // 나만 보기 (본인에게만 로드됨)
  final List<String> routines;
  final DateTime? updatedAt;

  PrayerEntry({
    required this.uid,
    this.topics = const [],
    this.private = const [],
    this.routines = const [],
    this.updatedAt,
  });

  bool get isEmpty => topics.isEmpty && private.isEmpty && routines.isEmpty;
  bool get isNotEmpty => !isEmpty;
  List<PrayerTopic> get all => [...topics, ...private];

  static List<PrayerTopic> _topicsOf(Map<String, dynamic>? m) =>
      (((m ?? const {})['topics'] as List?) ?? [])
          .map((e) => PrayerTopic.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

  factory PrayerEntry.fromDocs(
    DocumentSnapshot<Map<String, dynamic>> pub,
    DocumentSnapshot<Map<String, dynamic>>? priv,
  ) {
    final m = pub.data() ?? {};
    return PrayerEntry(
      uid: pub.id,
      topics: _topicsOf(m),
      private: priv == null ? const [] : _topicsOf(priv.data()),
      routines: _strs(m['routines']),
      updatedAt: _dt(m['updatedAt']),
    );
  }
}

// ─────────────────────────────────────────── 모임 / 출석
enum AttendStatus { present, absent, online, none }

AttendStatus attendFrom(String? s) => switch (s) {
      'present' => AttendStatus.present,
      'absent' => AttendStatus.absent,
      'online' => AttendStatus.online,
      _ => AttendStatus.none,
    };

String attendLabel(AttendStatus s) => switch (s) {
      AttendStatus.present => '참석',
      AttendStatus.absent => '불참',
      AttendStatus.online => '온라인',
      AttendStatus.none => '미체크',
    };

class Meeting {
  final String id, title, place, description, albumId, authorUid;
  final DateTime startAt;
  final DateTime? createdAt;

  Meeting({
    required this.id,
    required this.title,
    required this.startAt,
    this.place = '',
    this.description = '',
    this.albumId = '',
    this.authorUid = '',
    this.createdAt,
  });

  factory Meeting.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Meeting(
      id: d.id,
      title: (m['title'] ?? '') as String,
      startAt: _dt(m['startAt']) ?? DateTime.now(),
      place: (m['place'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      albumId: (m['albumId'] ?? '') as String,
      authorUid: (m['authorUid'] ?? '') as String,
      createdAt: _dt(m['createdAt']),
    );
  }

  bool get isUpcoming =>
      startAt.isAfter(DateTime.now().subtract(const Duration(hours: 4)));

  int get dday {
    final now = DateTime.now();
    return DateTime(startAt.year, startAt.month, startAt.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }
}

// ─────────────────────────────────────────── 앨범 / 사진
class Album {
  final String id, title, coverPublicId, meetingId, authorUid;
  final DateTime date;
  final int photoCount;

  Album({
    required this.id,
    required this.title,
    required this.date,
    this.coverPublicId = '',
    this.meetingId = '',
    this.authorUid = '',
    this.photoCount = 0,
  });

  factory Album.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Album(
      id: d.id,
      title: (m['title'] ?? '') as String,
      date: _dt(m['date']) ?? DateTime.now(),
      coverPublicId: (m['coverPublicId'] ?? '') as String,
      meetingId: (m['meetingId'] ?? '') as String,
      authorUid: (m['authorUid'] ?? '') as String,
      photoCount: (m['photoCount'] ?? 0) as int,
    );
  }
}

class Photo {
  final String id, publicId, format, uploaderUid;
  final int width, height, bytes;
  final List<String> likes;
  final bool hidden;
  final DateTime? createdAt;

  Photo({
    required this.id,
    required this.publicId,
    this.format = '',
    this.uploaderUid = '',
    this.width = 0,
    this.height = 0,
    this.bytes = 0,
    this.likes = const [],
    this.hidden = false,
    this.createdAt,
  });

  factory Photo.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Photo(
      id: d.id,
      publicId: (m['publicId'] ?? '') as String,
      format: (m['format'] ?? '') as String,
      uploaderUid: (m['uploaderUid'] ?? '') as String,
      width: (m['width'] ?? 0) as int,
      height: (m['height'] ?? 0) as int,
      bytes: (m['bytes'] ?? 0) as int,
      likes: _strs(m['likes']),
      hidden: (m['hidden'] ?? false) as bool,
      createdAt: _dt(m['createdAt']),
    );
  }

  /// 업로드 후 10분 안에는 올린 사람이 완전 취소 가능
  bool get cancellable =>
      createdAt != null &&
      DateTime.now().difference(createdAt!) < const Duration(minutes: 10);
}

// ─────────────────────────────────────────── 공지
class Notice {
  final String id, title, body, authorUid;
  final bool pinned;
  final DateTime? createdAt;
  final List<String> readBy;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    this.authorUid = '',
    this.pinned = false,
    this.createdAt,
    this.readBy = const [],
  });

  factory Notice.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Notice(
      id: d.id,
      title: (m['title'] ?? '') as String,
      body: (m['body'] ?? '') as String,
      authorUid: (m['authorUid'] ?? '') as String,
      pinned: (m['pinned'] ?? false) as bool,
      createdAt: _dt(m['createdAt']),
      readBy: _strs(m['readBy']),
    );
  }
}

// ─────────────────────────────────────────── 투표
class PollOption {
  final String id, label;
  final List<String> votes;
  PollOption({required this.id, required this.label, this.votes = const []});

  Map<String, dynamic> toMap() => {'id': id, 'label': label, 'votes': votes};

  factory PollOption.fromMap(Map<String, dynamic> m) => PollOption(
        id: (m['id'] ?? '') as String,
        label: (m['label'] ?? '') as String,
        votes: _strs(m['votes']),
      );
}

class Poll {
  final String id, question, authorUid;
  final List<PollOption> options;
  final DateTime? closesAt, createdAt;
  final bool closed, multi;

  Poll({
    required this.id,
    required this.question,
    this.options = const [],
    this.authorUid = '',
    this.closesAt,
    this.createdAt,
    this.closed = false,
    this.multi = false,
  });

  factory Poll.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Poll(
      id: d.id,
      question: (m['question'] ?? '') as String,
      options: ((m['options'] as List?) ?? [])
          .map((e) => PollOption.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      authorUid: (m['authorUid'] ?? '') as String,
      closesAt: _dt(m['closesAt']),
      createdAt: _dt(m['createdAt']),
      closed: (m['closed'] ?? false) as bool,
      multi: (m['multi'] ?? false) as bool,
    );
  }

  bool get isOver =>
      closed || (closesAt != null && closesAt!.isBefore(DateTime.now()));

  int get totalVotes => options.fold(0, (s, o) => s + o.votes.length);

  List<String> get voters {
    final s = <String>{};
    for (final o in options) {
      s.addAll(o.votes);
    }
    return s.toList();
  }
}

// ─────────────────────────────────────────── 정산
class ExtraItem {
  final String uid, label;
  final int amount;
  ExtraItem({required this.uid, required this.label, required this.amount});

  Map<String, dynamic> toMap() => {'uid': uid, 'label': label, 'amount': amount};

  factory ExtraItem.fromMap(Map<String, dynamic> m) => ExtraItem(
        uid: (m['uid'] ?? '') as String,
        label: (m['label'] ?? '') as String,
        amount: (m['amount'] ?? 0) as int,
      );
}

class Settlement {
  final String id, title, account, authorUid, memo;
  final int totalAmount, supportAmount;
  final List<String> participants, paid;
  final List<ExtraItem> extraItems;
  final DateTime? deadline, createdAt;

  Settlement({
    required this.id,
    required this.title,
    this.totalAmount = 0,
    this.supportAmount = 0,
    this.participants = const [],
    this.paid = const [],
    this.extraItems = const [],
    this.account = '',
    this.memo = '',
    this.authorUid = '',
    this.deadline,
    this.createdAt,
  });

  factory Settlement.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Settlement(
      id: d.id,
      title: (m['title'] ?? '') as String,
      totalAmount: (m['totalAmount'] ?? 0) as int,
      supportAmount: (m['supportAmount'] ?? 0) as int,
      participants: _strs(m['participants']),
      paid: _strs(m['paid']),
      extraItems: ((m['extraItems'] as List?) ?? [])
          .map((e) => ExtraItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      account: (m['account'] ?? '') as String,
      memo: (m['memo'] ?? '') as String,
      authorUid: (m['authorUid'] ?? '') as String,
      deadline: _dt(m['deadline']),
      createdAt: _dt(m['createdAt']),
    );
  }

  /// 교회 지원금을 뺀 금액을 1/N (10원 단위 올림)
  int get shareBase {
    final n = participants.length;
    if (n == 0) return 0;
    final net = totalAmount - supportAmount;
    if (net <= 0) return 0;
    final raw = net / n;
    return (raw / 10).ceil() * 10;
  }

  int extraFor(String uid) =>
      extraItems.where((e) => e.uid == uid).fold(0, (s, e) => s + e.amount);

  int amountFor(String uid) =>
      (participants.contains(uid) ? shareBase : 0) + extraFor(uid);

  List<String> get everyone =>
      <String>{...participants, ...extraItems.map((e) => e.uid)}.toList();

  int get collected =>
      paid.fold(0, (s, uid) => s + amountFor(uid));

  int get expected =>
      everyone.fold(0, (s, uid) => s + amountFor(uid));
}

// ─────────────────────────────────────────── 말씀 노트
class SermonNote {
  final String id, title, scripture, summary, reflection, authorUid;
  final DateTime date;
  final List<String> tags;
  final DateTime? createdAt;

  SermonNote({
    required this.id,
    required this.title,
    required this.date,
    this.scripture = '',
    this.summary = '',
    this.reflection = '',
    this.authorUid = '',
    this.tags = const [],
    this.createdAt,
  });

  factory SermonNote.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return SermonNote(
      id: d.id,
      title: (m['title'] ?? '') as String,
      date: _dt(m['date']) ?? DateTime.now(),
      scripture: (m['scripture'] ?? '') as String,
      summary: (m['summary'] ?? '') as String,
      reflection: (m['reflection'] ?? '') as String,
      authorUid: (m['authorUid'] ?? '') as String,
      tags: _strs(m['tags']),
      createdAt: _dt(m['createdAt']),
    );
  }
}
