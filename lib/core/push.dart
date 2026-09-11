import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import 'device_storage.dart';
import 'refs.dart';

/// 웹 푸시 알림(FCM)을 이 기기에서 켜고 끄는 일 — 애기애타 lib/push.ts 와 같은 흐름입니다.
///
/// 알림 허용은 **기기·브라우저마다 따로**라서, 켬/끔은 이 기기에 남기고
/// "받는 사람 목록"은 groups/{gid}/pushTokens 에 기기 단위 문서(문서 id = FCM 토큰)로 쌓입니다.
/// 실제 발송은 서버(netlify/functions/push.mts)가 합니다.
///
/// 아이폰은 사파리에서 바로 안 되고, "홈 화면에 추가"로 설치한 앱 안에서만(iOS 16.4 이상) 알림이 옵니다.

/// "이 기기에서 알림을 껐다"는 표시. 한 번 허용한 브라우저 권한은 끈다고 되돌아가지 않아서 따로 적습니다.
const _pushKey = 'sarangbang:push';

enum PushPermission { granted, denied, notDetermined, unsupported }

/// 방장이 웹 푸시 키(AppConfig.firebaseVapidKey)를 넣어 두었는지
bool get isPushConfigured => AppConfig.firebaseVapidKey.isNotEmpty;

Future<bool> _supported() async {
  try {
    return await FirebaseMessaging.instance.isSupported();
  } catch (_) {
    return false;
  }
}

Future<PushPermission> _permission() async {
  if (!await _supported()) return PushPermission.unsupported;
  final settings = await FirebaseMessaging.instance.getNotificationSettings();
  return switch (settings.authorizationStatus) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => PushPermission.granted,
    AuthorizationStatus.denied => PushPermission.denied,
    _ => PushPermission.notDetermined,
  };
}

/// 지금 이 기기에서 알림이 켜져 있는지 (권한이 있고, 내가 끄지 않았는지)
Future<bool> _isOn() async =>
    await _permission() == PushPermission.granted && deviceRead(_pushKey) != 'off';

/// 이 기기의 FCM 토큰을 받아 pushTokens 에 적어 둡니다. 권한이 이미 있을 때만 부릅니다.
Future<void> _upsertToken(String uid) async {
  final token = await FirebaseMessaging.instance.getToken(vapidKey: AppConfig.firebaseVapidKey);
  if (token == null || token.isEmpty) throw Exception('알림 토큰을 받지 못했어요.');
  await Refs.pushToken(token).set(
    {'uid': uid, 'refreshedAt': FieldValue.serverTimestamp()},
    SetOptions(merge: true),
  );
}

/// 이 기기에서 알림 켜기. 권한을 묻고(처음이면 브라우저 창), 허용되면 토큰을 등록합니다.
/// 돌려주는 값이 최종 권한 상태입니다.
Future<PushPermission> enablePush(String uid) async {
  if (!await _supported()) return PushPermission.unsupported;
  final settings = await FirebaseMessaging.instance.requestPermission();
  switch (settings.authorizationStatus) {
    case AuthorizationStatus.authorized:
    case AuthorizationStatus.provisional:
      break;
    case AuthorizationStatus.denied:
      return PushPermission.denied;
    default:
      return PushPermission.notDetermined;
  }
  await _upsertToken(uid);
  deviceWrite(_pushKey, 'on');
  return PushPermission.granted;
}

/// 이 기기에서 알림 끄기. 토큰 문서를 지우고 브라우저 구독도 풉니다.
Future<void> disablePush() async {
  // 끔 표시부터 남깁니다. 아래에서 실패해도 다시 켜지지는 않아야 합니다.
  deviceWrite(_pushKey, 'off');
  if (!isPushConfigured || !await _supported()) return;
  try {
    final token = await FirebaseMessaging.instance.getToken(vapidKey: AppConfig.firebaseVapidKey);
    if (token != null) {
      await Refs.pushToken(token).delete().catchError((_) {});
    }
    await FirebaseMessaging.instance.deleteToken();
  } catch (_) {
    // 이미 꺼져 있거나 토큰이 없는 경우 — 그냥 넘어갑니다.
  }
}

/// 앱을 열 때 조용히 토큰을 새로 고칩니다. 브라우저가 토큰을 말없이 바꿀 때가 있어서,
/// 이미 알림을 켠 기기라면 열 때마다 최신 토큰을 다시 적어 둡니다. 권한을 묻지 않고, 실패해도 조용합니다.
Future<void> syncPushToken(String uid) async {
  if (!isPushConfigured) return;
  try {
    if (await _isOn()) await _upsertToken(uid);
  } catch (_) {}
}

/// 설정 화면이 보여줄 상태
class PushState {
  final bool on;

  /// 아예 켤 수 없는 상태라면 그 이유. 켤 수 있으면 null
  final String? blocked;
  const PushState({required this.on, this.blocked});
}

const unsupportedMessage =
    '이 브라우저에서는 알림을 받을 수 없어요. 아이폰은 홈 화면에 추가한 뒤 그 아이콘으로 열어야 합니다.';

final pushStateProvider = FutureProvider<PushState>((ref) async {
  if (!await _supported()) return const PushState(on: false, blocked: unsupportedMessage);
  if (!isPushConfigured) {
    return const PushState(on: false, blocked: '알림이 아직 준비되지 않았어요. 방장에게 알려주세요.');
  }
  return PushState(on: await _isOn());
});

/// 켜기를 눌렀는데 권한이 안 났을 때 무엇이 막고 있는지
String pushPermissionProblem(PushPermission permission) => switch (permission) {
      PushPermission.denied =>
        '브라우저가 이 앱의 알림을 막아두었어요. 브라우저 설정에서 알림을 허용한 뒤 다시 켜주세요.',
      PushPermission.unsupported => unsupportedMessage,
      _ => '알림 허용을 눌러야 켜집니다.',
    };

enum PushKind { meeting, notice, poll, settlement }

/// "새 글을 올렸으니 그 사랑방 사람들에게 알림을 보내달라"고 서버에 부탁합니다.
///
/// 남의 이름으로 부를 수 없도록 로그인 토큰을 함께 보내고, 받는 사람과 문구는 서버가 원본 문서를 보고 정합니다.
/// 수정할 때는 부르지 않습니다 — 새로 올린 그 한 번만 알립니다.
/// 실패해도 아무것도 하지 않습니다. 알림이 한 번 안 간 것뿐이라 오류를 띄울 일이 아닙니다.
Future<void> requestPush(PushKind kind, {required String roomId, required String id}) async {
  try {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) return;
    await http.post(
      Uri.base.resolve('/.netlify/functions/push'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
      body: jsonEncode({
        'groupId': AppConfig.groupId,
        'roomId': roomId,
        'kind': kind.name,
        'id': id,
      }),
    );
  } catch (_) {
    // 조용히 넘어갑니다.
  }
}
