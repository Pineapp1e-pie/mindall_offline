import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

/** Получает OAuth2 access token для Firebase через service account JWT. */
async function getFirebaseAccessToken(): Promise<string> {
  const sa = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!);

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const b64url = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');

  const signingInput = `${b64url(header)}.${b64url(payload)}`;

  const pem = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----\n/, '')
    .replace(/\n-----END PRIVATE KEY-----\n?/, '')
    .replace(/\n/g, '');

  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  );

  const encodedSig = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  const jwt = `${signingInput}.${encodedSig}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await res.json();
  if (!data.access_token) throw new Error(`Token error: ${JSON.stringify(data)}`);
  return data.access_token;
}

/** Отправляет FCM push одному токену. */
async function sendPush(
  fcmToken: string,
  accessToken: string,
  projectId: string,
): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: 'Как ты сегодня?',
            body: 'Запиши своё настроение',
          },
          android: {
            priority: 'HIGH',
            notification: { channel_id: 'mood_reminder' },
          },
        },
      }),
    },
  );
  if (!res.ok) {
    const err = await res.text();
    console.error(`FCM error for token ${fcmToken.slice(-8)}: ${err}`);
  }
  return res.ok;
}

Deno.serve(async () => {
  const now = new Date();
  const hourUtc = now.getUTCHours();
  const minuteUtc = now.getUTCMinutes();

  const { data: rows, error } = await supabase
    .from('push_tokens')
    .select('fcm_token, notif_hour, notif_minute, utc_offset_minutes')
    .eq('notif_enabled', true);

  if (error) return new Response(error.message, { status: 500 });
  if (!rows || rows.length === 0) return new Response('no tokens', { status: 200 });

  const sa = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!);
  const accessToken = await getFirebaseAccessToken();

  let sent = 0;
  for (const row of rows) {
    // Переводим локальное время пользователя в UTC и сравниваем
    const localMinutes = row.notif_hour * 60 + row.notif_minute;
    const utcMinutes = ((localMinutes - row.utc_offset_minutes) % 1440 + 1440) % 1440;
    const targetHour = Math.floor(utcMinutes / 60);
    const targetMinute = utcMinutes % 60;

    if (targetHour === hourUtc && targetMinute === minuteUtc) {
      const ok = await sendPush(row.fcm_token, accessToken, sa.project_id);
      if (ok) sent++;
    }
  }

  console.log(`Sent ${sent} notifications at ${hourUtc}:${String(minuteUtc).padStart(2, '0')} UTC`);
  return new Response(`sent: ${sent}`, { status: 200 });
});
