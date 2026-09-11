/**
 * 사랑방 푸시 알림 발송 — 애기애타 10기 앱의 /api/push/* 창구와 같은 방식입니다.
 *
 * 새 모임·공지·투표·정산을 올린 사람의 앱이 이 창구를 부르면(lib/core/push.dart 의 requestPush),
 * 서버가 원본 문서를 직접 읽어 올린 본인인지 확인한 뒤 그 사랑방 멤버들의 기기로 FCM 알림을 보냅니다.
 * 받는 사람과 알림 문구는 서버가 문서를 보고 정합니다 — 앱이 보낸 글자를 그대로 믿지 않습니다.
 *
 * Cloud Functions(유료 요금제)를 쓰지 않으려고 Netlify 함수로 둡니다.
 * Netlify 환경변수 FIREBASE_SERVICE_ACCOUNT(서비스 계정 JSON 한 줄)가 있어야 알림이 나갑니다.
 * 없으면 조용히 { ok: false, reason: "not-configured" } 만 돌려줍니다.
 *
 * 부르는 주소: POST /.netlify/functions/push
 *   Authorization: Bearer <Firebase ID 토큰>
 *   { groupId, roomId, kind: "meeting" | "notice" | "poll" | "settlement", id }
 */
import { cert, getApps, initializeApp, type App } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, type DocumentReference, type DocumentSnapshot } from "firebase-admin/firestore";
import { getMessaging, type Messaging } from "firebase-admin/messaging";

type Kind = "meeting" | "notice" | "poll" | "settlement";

const COLLECTION: Record<Kind, string> = {
  meeting: "meetings",
  notice: "notices",
  poll: "polls",
  settlement: "settlements",
};

/** lib/app_config.dart 의 AppConfig.rooms 와 같아야 합니다 (id → 이름). */
const ROOM_NAMES: Record<string, string> = { hj: "희진사랑방", pg: "평강사랑방", all: "전체 사랑방" };
const ALL_ROOM = "all";

/** 문서 경로 조각으로 쓸 값만 받습니다. */
const SAFE_ID = /^[\w-]{1,120}$/;

/** FCM이 한 번에 받는 토큰 수 상한 */
const FCM_MULTICAST_LIMIT = 500;
/** Firestore "in" 질의는 한 번에 30개까지 */
const IN_QUERY_LIMIT = 30;
const BODY_MAX_LENGTH = 120;

function adminApp(): App | null {
  const existing = getApps()[0];
  if (existing) return existing;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as { project_id?: string; client_email?: string; private_key?: string };
    // 환경변수에 붙여넣을 때 줄바꿈이 \n 두 글자로 바뀌는 경우가 많아 되돌립니다.
    const privateKey = String(parsed.private_key ?? "").replace(/\\n/g, "\n");
    if (!privateKey || !parsed.client_email || !parsed.project_id) return null;
    return initializeApp({
      credential: cert({ projectId: parsed.project_id, clientEmail: parsed.client_email, privateKey }),
    });
  } catch {
    return null;
  }
}

const reply = (body: Record<string, unknown>, status = 200) => Response.json(body, { status });

/** 한국 시간 기준 "9월 14일 (일) 오후 3:00" */
function formatWhen(date: Date): string {
  const parts = new Intl.DateTimeFormat("ko-KR", {
    timeZone: "Asia/Seoul",
    month: "numeric",
    day: "numeric",
    weekday: "short",
    hour: "numeric",
    minute: "2-digit",
  }).formatToParts(date);
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "";
  return `${get("month")}월 ${get("day")}일 (${get("weekday")}) ${get("dayPeriod")} ${get("hour")}:${get("minute")}`;
}

/** 알림 문구와 눌렀을 때 열 주소 — 앱의 알림함(lib/core/inbox.dart)과 같은 문구입니다. */
function describe(kind: Kind, snap: DocumentSnapshot, roomId: string, id: string) {
  const roomName = ROOM_NAMES[roomId] ?? "사랑방";
  const text = (field: string) => String(snap.get(field) ?? "").trim();
  switch (kind) {
    case "meeting": {
      const startAt = snap.get("startAt");
      const when = startAt && typeof startAt.toDate === "function" ? formatWhen(startAt.toDate()) : "";
      return {
        title: `새 모임 · ${text("title") || "모임"}`,
        body: [roomName, when].filter(Boolean).join(" · "),
        url: `/meetings/${roomId}/${id}`,
      };
    }
    case "notice":
      return { title: `새 공지 · ${text("title") || "공지"}`, body: text("body").split("\n")[0], url: "/more/notices" };
    case "poll":
      return { title: `새 투표 · ${text("question") || "투표"}`, body: roomName, url: "/more/polls" };
    case "settlement":
      return { title: `새 정산 · ${text("title") || "정산"}`, body: roomName, url: "/more/settlements" };
  }
}

async function tokensFor(group: DocumentReference, uids: string[]): Promise<string[]> {
  const tokens: string[] = [];
  for (let i = 0; i < uids.length; i += IN_QUERY_LIMIT) {
    const snap = await group
      .collection("pushTokens")
      .where("uid", "in", uids.slice(i, i + IN_QUERY_LIMIT))
      .get();
    snap.forEach((doc) => tokens.push(doc.id));
  }
  return tokens;
}

async function sendToTokens(
  group: DocumentReference,
  messaging: Messaging,
  tokens: string[],
  payload: { title: string; body: string; url: string; tag: string },
) {
  const unique = [...new Set(tokens)].filter(Boolean);
  const body = payload.body.length > BODY_MAX_LENGTH ? `${payload.body.slice(0, BODY_MAX_LENGTH)}…` : payload.body;
  let sent = 0;
  let failed = 0;
  const dead: string[] = [];

  for (let i = 0; i < unique.length; i += FCM_MULTICAST_LIMIT) {
    const chunk = unique.slice(i, i + FCM_MULTICAST_LIMIT);
    /*
     * notification 없이 data 만 보냅니다. 서비스워커(web/firebase-messaging-sw.js)가 이 값으로
     * 알림을 직접 띄워서 제목·아이콘·묶음(tag)이 우리가 정한 대로 보입니다.
     * fcmOptions.link 는 https 로 시작하는 온전한 주소만 받아 쓰지 않습니다.
     */
    const response = await messaging.sendEachForMulticast({
      tokens: chunk,
      data: { title: payload.title, body, url: payload.url, tag: payload.tag },
      webpush: { headers: { Urgency: "high", TTL: "1800" } },
    });
    sent += response.successCount;
    failed += response.failureCount;
    response.responses.forEach((result, index) => {
      const code = result.error?.code ?? "";
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token" ||
        code === "messaging/invalid-argument"
      ) {
        dead.push(chunk[index]);
      }
    });
  }

  // 이제 없는 기기의 토큰은 지웁니다.
  await Promise.all(dead.map((token) => group.collection("pushTokens").doc(token).delete().catch(() => {})));
  return { sent, failed };
}

export default async (request: Request) => {
  if (request.method !== "POST") return reply({ ok: false, reason: "method-not-allowed" }, 405);

  const app = adminApp();
  if (!app) return reply({ ok: false, reason: "not-configured" });
  const db = getFirestore(app);

  const header = request.headers.get("authorization") ?? "";
  const idToken = header.startsWith("Bearer ") ? header.slice(7) : "";
  let senderUid: string;
  try {
    senderUid = (await getAuth(app).verifyIdToken(idToken)).uid;
  } catch {
    return reply({ ok: false, reason: "unauthorized" }, 401);
  }

  const input = (await request.json().catch(() => null)) as Record<string, unknown> | null;
  const groupId = String(input?.groupId ?? "");
  const roomId = String(input?.roomId ?? "");
  const id = String(input?.id ?? "");
  const kind = String(input?.kind ?? "") as Kind;
  if (!SAFE_ID.test(groupId) || !SAFE_ID.test(roomId) || !SAFE_ID.test(id) || !(kind in COLLECTION)) {
    return reply({ ok: false, reason: "bad-request" }, 400);
  }

  const group = db.collection("groups").doc(groupId);
  const snap = await group.collection("rooms").doc(roomId).collection(COLLECTION[kind]).doc(id).get();
  if (!snap.exists) return reply({ ok: false, reason: "not-found" }, 404);
  // 그 글을 올린 본인만 알림을 보낼 수 있습니다.
  if (snap.get("authorUid") !== senderUid) return reply({ ok: false, reason: "forbidden" }, 403);

  /*
   * 두 번 눌리거나 다시 불려도 알림은 한 번만 — 보낸 표시를 남기고, 이미 있으면 돌아갑니다.
   * create 는 문서가 있으면 실패하므로 동시에 두 번 들어와도 한쪽만 통과합니다.
   * pushLog 는 서버만 쓰는 자리라 보안 규칙에 적지 않습니다(규칙에 없으면 앱에서는 닫혀 있음).
   */
  try {
    await group.collection("pushLog").doc(`${kind}:${roomId}:${id}`).create({ sentBy: senderUid, sentAt: new Date() });
  } catch {
    return reply({ ok: true, sent: 0, reason: "already-sent" });
  }

  // 받는 사람: 그 사랑방 멤버(전체 사랑방이면 모두), 올린 사람은 빼고.
  const members = await group.collection("members").select("roomId").get();
  const recipients = members.docs
    .filter((doc) => roomId === ALL_ROOM || doc.get("roomId") === roomId)
    .map((doc) => doc.id)
    .filter((uid) => uid !== senderUid);
  if (recipients.length === 0) return reply({ ok: true, sent: 0 });

  const tokens = await tokensFor(group, recipients);
  if (tokens.length === 0) return reply({ ok: true, sent: 0 });

  const { title, body, url } = describe(kind, snap, roomId, id);
  const result = await sendToTokens(group, getMessaging(app), tokens, { title, body, url, tag: `${kind}:${roomId}:${id}` });
  return reply({ ok: true, ...result });
};
