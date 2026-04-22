import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const adminClient = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response('Unauthorized', { status: 401 });
  }

  // Создаём клиент с токеном пользователя — Supabase верифицирует его сам
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await userClient.auth.getUser();

  if (authError || !user) {
    return new Response('Unauthorized', { status: 401 });
  }

  const userId = user.id;

  // Удаляем файлы из Storage (photos и voices хранятся в папке userId/)
  for (const bucket of ['photos', 'voices']) {
    const { data: files } = await adminClient.storage.from(bucket).list(userId);
    if (files && files.length > 0) {
      const paths = files.map((f: { name: string }) => `${userId}/${f.name}`);
      await adminClient.storage.from(bucket).remove(paths);
    }
  }

  // Удаляем все данные пользователя из таблиц
  await adminClient.from('mood_entry_tags').delete().eq('user_id', userId);
  await adminClient.from('context_details').delete().eq('user_id', userId);
  await adminClient.from('weather_data').delete().eq('user_id', userId);
  await adminClient.from('health_data').delete().eq('user_id', userId);
  await adminClient.from('mood_entries').delete().eq('user_id', userId);
  await adminClient.from('user_achievements').delete().eq('user_id', userId);
  await adminClient.from('push_tokens').delete().eq('user_id', userId);
  await adminClient.from('profiles').delete().eq('user_id', userId);

  // Удаляем пользователя из Auth
  const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);

  if (deleteError) {
    return new Response(JSON.stringify({ error: deleteError.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
