-- Таблица FCM-токенов и настроек уведомлений
create table if not exists push_tokens (
  user_id            uuid references auth.users(id) on delete cascade primary key,
  fcm_token          text        not null,
  notif_enabled      boolean     not null default false,
  notif_hour         smallint    not null default 18,
  notif_minute       smallint    not null default 0,
  utc_offset_minutes int         not null default 0,
  updated_at         timestamptz not null default now()
);

alter table push_tokens enable row level security;

create policy "Users manage own token"
  on push_tokens for all
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);
