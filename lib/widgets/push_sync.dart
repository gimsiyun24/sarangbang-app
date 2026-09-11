import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../core/push.dart';

/// 알림을 이미 켜 둔 기기의 토큰을 앱을 열 때마다 새로 적어 둡니다 — 애기애타 PushSync 와 같습니다.
///
/// FCM 토큰은 브라우저가 말없이 바꿔버릴 때가 있습니다. 그러면 서버가 옛 토큰으로 보내다 조용히 실패하고,
/// "알림을 켰는데 안 온다"가 됩니다. 열 때 한 번 다시 적어두면 그 틈이 없습니다.
/// 권한을 새로 묻지는 않고, 화면에는 아무것도 그리지 않습니다.
class PushSync extends StatefulWidget {
  final Widget child;
  const PushSync({super.key, required this.child});

  @override
  State<PushSync> createState() => _PushSyncState();
}

class _PushSyncState extends State<PushSync> {
  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) syncPushToken(uid);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
