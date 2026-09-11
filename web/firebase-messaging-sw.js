/*
 * 사랑방 앱 웹 푸시 알림 서비스워커 — 애기애타 앱의 firebase-messaging-sw.js 와 같은 동작입니다.
 *
 * firebase_messaging 이 알림 토큰을 받을 때 이 주소(/firebase-messaging-sw.js)를 찾아 등록합니다.
 * 서버(netlify/functions/push.mts)는 notification 없이 data 만 보내고, 알림은 여기서 직접 띄웁니다 —
 * 그래야 브라우저가 제멋대로 띄우지 않고 제목·아이콘·묶음(tag)이 우리가 정한 대로 보입니다.
 *
 * ★ Firebase 설정값은 lib/app_config.dart 와 같아야 합니다. 브라우저에 공개되는 값이라 파일에 적어도 됩니다.
 * ★ JS SDK 버전은 firebase_core_web 이 쓰는 버전과 맞춥니다
 *   (pubspec.lock 의 firebase_core_web → lib/src/firebase_sdk_version.dart).
 * 서비스워커 안에서는 패키지를 못 쓰므로 gstatic 의 compat 빌드를 importScripts 로 불러옵니다(FCM 표준 방식).
 */
importScripts("https://www.gstatic.com/firebasejs/12.18.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/12.18.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyA0Aesa1pnI36I2KbkgZd0Zd-QsCMWSPfo",
  authDomain: "church-c97c0.firebaseapp.com",
  projectId: "church-c97c0",
  messagingSenderId: "1094696874902",
  appId: "1:1094696874902:web:192b787fdb6468bc3123b7",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const d = (payload && payload.data) || {};
  const options = {
    body: d.body || "",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    data: { url: d.url || "/" },
  };
  /*
   * 같은 글의 알림은 tag 로 묶어 한 칸에 겹칩니다. renotify 는 tag 가 있을 때만 붙입니다 —
   * tag 없이 renotify 를 주면 크롬이 오류를 내고 알림이 아예 안 뜹니다.
   */
  if (d.tag) {
    options.tag = d.tag;
    options.renotify = true;
  }
  self.registration.showNotification(d.title || "사랑방", options);
});

/* 알림을 누르면 이미 열린 앱 창을 그 화면으로 옮기고, 없으면 새로 엽니다. */
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const target = (event.notification.data && event.notification.data.url) || "/";
  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((list) => {
      for (const client of list) {
        if (client.url.includes(target) && "focus" in client) return client.focus();
      }
      for (const client of list) {
        if ("navigate" in client && "focus" in client) {
          return client.navigate(target).then(() => client.focus());
        }
      }
      return clients.openWindow(target);
    }),
  );
});
