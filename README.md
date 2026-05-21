# mindall_offline — дневник настроения и ментального здоровья

Flutter-приложение для отслеживания эмоционального состояния с аналитикой, трекером здоровья, кризисным детектором и синхронизацией с облаком.

---

## Содержание

1. [Описание приложения](#1-описание-приложения)
2. [Структура проекта](#2-структура-проекта)
3. [Архитектура и слои](#3-архитектура-и-слои)
4. [База данных (Drift/SQLite)](#4-база-данных-driftsqlite)
5. [Поток данных](#5-поток-данных)
6. [Навигация и экраны](#6-навигация-и-экраны)
7. [Сервисы](#7-сервисы)
8. [Синхронизация с Supabase](#8-синхронизация-с-supabase)
9. [Система ачивок](#9-система-ачивок)
10. [Аналитика и графики](#10-аналитика-и-графики)
11. [Кризисный детектор](#11-кризисный-детектор)
12. [Здоровье и цикл](#12-здоровье-и-цикл)
13. [Уведомления](#13-уведомления)
14. [Экспорт данных](#14-экспорт-данных)
15. [Зависимости](#15-зависимости)
16. [Запуск проекта](#16-запуск-проекта)

---

## 1. Описание приложения

**mindall_offline** — мобильный дневник настроения, позволяющий пользователю:

- **Фиксировать настроение** из 36 эмоций, расположенных в 2D-пространстве (ось X: негативное↔позитивное, ось Y: спокойное↔активное)
- **Добавлять контекст**: место, вид деятельности, социальное окружение, погода
- **Записывать заметки**: текст, голосовые сообщения, фотографии
- **Отслеживать здоровье**: сон, шаги (через Health API), фазу менструального цикла
- **Анализировать динамику**: графики настроения по дням/неделям/месяцам/году, корреляции
- **Получать предупреждения** при кризисных ситуациях (ключевые слова) и затяжных негативных стриках
- **Зарабатывать ачивки** за регулярность ведения дневника
- **Экспортировать отчёты** в Excel и PDF

Язык интерфейса: русский.  
Бэкенд: Supabase (PostgreSQL + Storage). Локальная БД: SQLite (Drift ORM).

---

## 2. Структура проекта

```
lib/
├── main.dart                          # Точка входа, инициализация, Provider-дерево
├── background/
│   └── step_sync_worker.dart          # WorkManager: ночная синхронизация шагов
├── data/
│   ├── local/
│   │   ├── app_database.dart          # Схема БД, версии, миграции
│   │   ├── app_database.g.dart        # Сгенерированный код Drift (не редактировать)
│   │   ├── debug/
│   │   │   └── fake_data_generator.dart
│   │   ├── mappers/
│   │   │   └── weather_mapper.dart
│   │   ├── repositories/
│   │   │   ├── local_repository.dart          # Абстрактный интерфейс
│   │   │   ├── local_repository_impl.dart     # SQL-реализация
│   │   │   └── weather_repository.dart
│   │   ├── static/
│   │   │   ├── moods.dart             # Enum MoodCategory
│   │   │   ├── moods_seed.dart        # 36 настроений с координатами
│   │   │   ├── moods_initializer.dart # Заполнение таблицы moods при первом запуске
│   │   │   ├── context_tags_seed.dart # Предустановленные теги
│   │   │   ├── weather_factory.dart
│   │   │   └── weather_labels.dart
│   │   └── tables/                    # Drift-таблицы
│   │       ├── mood_entries.dart
│   │       ├── mood_entry_tags.dart
│   │       ├── context_tags.dart
│   │       ├── context_details.dart
│   │       ├── weather_data.dart
│   │       ├── health_data.dart
│   │       ├── daily_mood_stats.dart
│   │       └── user_achievements.dart
│   └── remote/
│       ├── supabase_sync_service.dart # Синхронизация с Supabase
│       └── file_storage_service.dart  # Загрузка фото/аудио в Supabase Storage
├── domain/
│   ├── models/
│   │   ├── achievement.dart           # Модель ачивки + каталог kAchievements
│   │   ├── chart_models.dart          # TimePoint, ScatterPoint, DayStats
│   │   ├── mood_entry_draft.dart      # Черновик записи (состояние формы)
│   │   ├── mood_entry_with_mood.dart  # Результат JOIN-запроса
│   │   ├── weather_draft.dart
│   │   ├── health_draft.dart
│   │   └── user_profile.dart          # Пол, имя, настройки цикла
│   └── services/
│       ├── achievement_service.dart   # Стрик, логика разблокировки
│       ├── analytics_service.dart     # Данные для графиков
│       ├── crisis_detector.dart       # NLP: ключевые слова кризиса
│       ├── cycle_calculator.dart      # Фаза менструального цикла
│       ├── daily_mood_analyzer.dart   # Агрегация дня → DailyMoodStats
│       ├── export_service.dart        # Excel/PDF
│       ├── health_service.dart        # Обёртка Health API
│       ├── notification_service.dart  # FCM + локальные уведомления
│       └── user_profile_service.dart  # SharedPreferences, ChangeNotifier
└── ui/
    ├── app_route.dart                 # Кастомный переход (fade + slide)
    ├── assets/
    │   ├── fonts/                     # DotGothic16, Inter
    │   ├── pixelariticons_svg/        # SVG-иконки
    │   ├── mood_colors.dart
    │   └── category_colors.dart
    ├── models/
    │   └── mood_entry_ui_model.dart
    ├── screens/
    │   ├── auth_screen.dart
    │   ├── reset_password_screen.dart
    │   ├── main_nav_scaffold.dart     # Нижняя навигация: Главная / Аналитика / Профиль
    │   ├── home_container.dart
    │   ├── home_screen.dart
    │   ├── mood_selection_screen.dart
    │   ├── mood_category_screen.dart
    │   ├── mood_context_screen.dart
    │   ├── mood_note_screen.dart
    │   ├── health_step.dart
    │   ├── health_content.dart
    │   ├── manual_health_screen.dart
    │   ├── manual_weather_screen.dart
    │   ├── weather_step.dart
    │   ├── weather_content.dart
    │   ├── mood_entry_detail_screen.dart
    │   ├── analytics_screen.dart
    │   ├── correlation_screen.dart
    │   ├── cycle_setup_screen.dart
    │   └── profile_screen.dart
    └── widgets/
        ├── analytics/
        │   ├── chart_shared.dart
        │   ├── day_type_legend.dart
        │   ├── month_calendar.dart
        │   ├── quadrant_breakdown.dart
        │   ├── week_chart.dart
        │   └── year_bars_chart.dart
        ├── achievement_popup.dart
        ├── bottom_button.dart
        ├── pixel_card.dart
        ├── pixel_circle.dart
        ├── pixel_note_card.dart
        ├── pixel_photo_card.dart
        ├── step_indicator.dart
        ├── svg_icon.dart
        ├── tag_section.dart
        └── voice_player.dart
```

---

## 3. Архитектура и слои

Приложение использует **офлайн-первый** подход с тремя слоями:

```
UI (Screens & Widgets)
        ↕ Provider (context.read / context.watch)
Domain (Services + Models)
        ↕ LocalRepository (абстракция)
Data (LocalRepositoryImpl + SupabaseSyncService)
        ↕ Drift ORM             ↕ Supabase SDK
     SQLite (локально)     PostgreSQL (облако)
```

### Управление состоянием

- **Provider** — внедрение зависимостей и реактивное состояние
- **ChangeNotifier** — `UserProfileService` уведомляет виджеты при изменении профиля
- **Drift streams** — `watchMoodEntriesForDay()` возвращает `Stream`, `HomeScreen` автоматически перестраивается при изменении БД
- **StatefulWidget** — локальное состояние форм и черновиков

### Инициализация (`main.dart`)

```

AppDatabase()  →  LocalRepositoryImpl
                  SupabaseSyncService
                  AchievementService
UserProfileService.init()       ← SharedPreferences
MoodsInitializer.init()         ← Seeds 36 moods
ContextTagsInitializer.init()   ← Seeds context tags
initWorkManager()               ← Фоновый синк шагов
NotificationService.init()      ← FCM setup
MultiProvider(...)              ← DI-дерево
```

---

## 4. База данных (Drift/SQLite)

Версия схемы: **3** (с миграциями).

### Таблицы

#### `moods` — справочник настроений (сидовые данные)
| Поле | Тип | Описание |
|------|-----|----------|
| id | int PK | |
| name | String | Название ("Радость", "Грусть"…) |
| x | double | Ось позитивности: −1.0 … +1.0 |
| y | double | Ось активности: −1.0 … +1.0 |
| category | String | negativeActive \| negativeCalm \| positiveActive \| positiveCalm |

#### `mood_entries` — записи настроения
| Поле | Тип | Описание |
|------|-----|----------|
| id | int PK auto | |
| userId | String | Supabase user.id |
| moodId | int FK→moods | Выбранное настроение |
| createdAt | DateTime | Unix-секунды (Drift `currentDateAndTime`) |

#### `context_tags` — теги контекста
| Поле | Тип | Описание |
|------|-----|----------|
| id | int PK auto | |
| name | String | Текст тега |
| type | String | place \| activity \| social \| cloudiness \| temperature \| precipitation |
| isCustom | bool | Добавлен пользователем |
| isActive | bool | false = удалён (soft delete) |

#### `mood_entry_tags` — связь записи с тегами (M:N)
| Поле | Тип |
|------|-----|
| moodEntryId | int FK→mood_entries |
| tagId | int FK→context_tags |
PK: (moodEntryId, tagId)

#### `context_details` — заметки и медиа
| Поле | Тип | Описание |
|------|-----|----------|
| id | int PK auto | |
| moodEntryId | int FK | |
| note | String? | Текст заметки |
| voicePath | String? | Локальный путь к аудио |
| photoPath | String? | Локальный путь к фото |

#### `weather_data` — погода на момент записи
| Поле | Тип | Описание |
|------|-----|----------|
| id | int PK auto | |
| moodEntryId | int FK | |
| source | String | "auto" \| "manual" |
| temperatureCategory | String | veryCold \| cold \| cool \| comfortable \| warm \| hot |
| rawTemperature | double? | Фактическая температура °C |
| precipitation | String? | none \| rain \| snow \| fog |
| cloudiness | String? | sunny \| cloudy \| overcast |

#### `health_data` — данные здоровья за день
| Поле | Тип | Описание |
|------|-----|----------|
| id | int PK auto | |
| date | DateTime UNIQUE | Только дата (00:00:00) |
| sleepMinutes | int? | Минуты сна |
| stepsAmount | int? | Количество шагов |
| cyclePhase | String? | menstruation \| follicular \| ovulation \| luteal |
| source | String? | "auto" \| "manual" |

#### `daily_mood_stats` — дневная агрегация для аналитики
| Поле | Тип | Описание |
|------|-----|----------|
| id | int PK auto | |
| date | DateTime | День |
| avgX | double | Среднее по оси позитивности |
| avgY | double | Среднее по оси активности |
| moodValue | double | Значение для графиков |
| dayType | String | stable\_positiveActive \| contrast \| positive \| negative … |

#### `user_achievements` — прогресс ачивок
| Поле | Тип | Описание |
|------|-----|----------|
| userId | String PK | |
| achievementId | String PK | |
| isAchieved | bool | Разблокирована |
| achievedAt | DateTime? | Когда разблокирована |
| synced | bool | Отправлена в Supabase |

### Важно о `created_at`

Drift использует `currentDateAndTime` = `strftime('%s', CURRENT_TIMESTAMP)` → хранит **Unix-секунды**, не миллисекунды. В сырых SQL-запросах нужно использовать:
```sql
date(created_at, 'unixepoch', 'localtime')  -- правильно
date(created_at / 1000, 'unixepoch', ...)   -- НЕПРАВИЛЬНО (даст 1970-е годы)
```

### Миграции

| Версия | Изменения |
|--------|-----------|
| 1 → 2 | Добавлена таблица `user_achievements` |
| 2 → 3 | Удалён столбец `notified` из ачивок, чистка схемы |

---

## 5. Поток данных

### Создание записи настроения

```
Пользователь выбирает настроение (MoodSelectionScreen)
  ↓ MoodEntryDraft (черновик передаётся между экранами)
MoodContextScreen → добавляет теги (place/activity/social)
MoodNoteScreen    → добавляет заметку/фото/голос
HealthStep        → добавляет сон/шаги/фазу цикла
WeatherStep       → добавляет погоду
  ↓ Нажатие «Сохранить»
LocalRepository.saveFullEntry(draft)
  ├── INSERT mood_entries
  ├── INSERT context_details
  ├── INSERT weather_data
  ├── INSERT mood_entry_tags (для каждого тега)
  ├── INSERT/UPDATE health_data
  └── DailyMoodAnalyzer.analyzeDay() → UPDATE daily_mood_stats
       ↓
AchievementService.checkAfterEntrySaved()
  ├── calculateStreak()
  ├── hasAllMoodCategories()
  └── markAchievementAchieved() если условие выполнено
       ↓ показ AchievementUnlockDialog (если новые)
unawaited(SupabaseSyncService.syncAll())  ← фоновая синхронизация
Navigator → MainNavScaffold
```

### Чтение данных для главного экрана

```
HomeScreen
  └── LocalRepository.watchMoodEntriesForDay(date)
        ↓ Stream<List<MoodEntryWithMood>>
        ↓ (автообновление при INSERT/DELETE в mood_entries)
      ListView из MoodEntryUiModel
```

### Аналитика

```
AnalyticsScreen
  └── AnalyticsService.getMoodTimeline(from, to)
        ↓ LocalRepository.getMoodEntriesWithMoodForPeriod()
        ↓ Агрегация по дням → List<TimePoint>
      LineChart (fl_chart)
```

---

## 6. Навигация и экраны

### Авторизация

```
AuthScreen (вход/регистрация)
  ↓ при успехе
CycleSetupScreen (только для женщин)
  ↓
MainNavScaffold
```

Поддержка deep links: `/reset_password?token=...` → `ResetPasswordScreen`

### Основная навигация (Bottom Nav)

```
MainNavScaffold
├── [0] HomeContainer
│     ├── DatePicker (выбор даты)
│     ├── HomeScreen (список записей за день)
│     └── FAB (+) → многошаговый флоу создания записи
├── [1] AnalyticsScreen
│     ├── Переключатель: День / Неделя / Месяц / Год
│     ├── Графики настроения
│     └── Кнопки: Экспорт, Корреляции → CorrelationScreen
└── [2] ProfileScreen
      ├── Имя и пол
      ├── Настройки цикла → CycleSetupScreen
      ├── Уведомления (время, вкл/выкл)
      ├── Достижения (сетка ачивок)
      └── Выход из аккаунта
```

### Многошаговый флоу создания записи

```
MoodSelectionScreen (2D-выбор настроения)
  ↓
MoodCategoryScreen (если нужно уточнить категорию)
  ↓
MoodContextScreen (теги: место / действие / общество)
  ↓
MoodNoteScreen (заметка + голос + фото)
  ↓
HealthStep (сон / шаги / цикл)
  ↓
WeatherStep (погода: температура / осадки / облачность)
  ↓ Сохранить
MainNavScaffold
```

### Детальный просмотр записи

```
HomeScreen → (тап на запись) → MoodEntryDetailScreen
  ├── Редактировать → возврат в MoodContextScreen с заполненным черновиком
  └── Удалить → подтверждение → LocalRepository.deleteEntry() + Supabase queue
```

---

## 7. Сервисы

### `AchievementService`

Отвечает за разблокировку ачивок после каждой сохранённой записи.

**Методы:**
- `initIfNeeded(userId)` — создаёт строки ачивок если их нет; всегда вызывает `checkAfterEntrySaved`
- `checkAfterEntrySaved(userId)` — проверяет все незавершённые ачивки, возвращает список новых
- `calculateStreak(userId)` — считает непрерывный стрик дней подряд

**Логика стрика:** берёт даты всех записей (`getUniqueMoodEntryDates`), начинает с самой последней, считает сколько дней подряд идут без пропуска. Стрик начинается с сегодня или вчера (иначе 0).

### `DailyMoodAnalyzer`

После каждого сохранения записи агрегирует все настроения за день:
- Считает `avgX`, `avgY` из координат всех настроений
- Определяет `dayType`: `stable_*` (все в одной категории), `contrast` (есть и позитивные, и негативные), `positive`/`negative`

### `CycleCalculator`

Вычисляет фазу цикла из `CycleSettings`:
```
дни_с_начала = (дата - lastPeriodStart) % cycleLengthDays
≤ periodDurationDays           → menstruation
≈ 14 день (±1)                 → ovulation
< 14 дней (и не менструация)   → follicular
> 14 дней (и не менструация)   → luteal
```

### `UserProfileService` (ChangeNotifier)

Хранит в `SharedPreferences`: пол, имя, настройки цикла, время уведомлений. Уведомляет слушателей при изменении → UI перестраивается без перезапуска.

### `AnalyticsService`

Генерирует данные для графиков:
- `getMoodTimeline(from, to)` → `List<TimePoint>` для линейного графика
- `getDayEntries(date)` → scatter внутри дня
- `getMoodVsSleep()`, `getMoodVsSteps()` → корреляционные scatter
- `getMonthQuadrants()` → разбивка по квадрантам

### `HealthService`

Обёртка над пакетом `health` (Health Connect на Android / HealthKit на iOS):
- `requestPermissions()` — запрашивает доступ к SLEEP и STEPS
- `getSleepMinutes(date)` — сон за указанный день
- `getStepAmount(date)` — шаги за указанный день

### `ExportService`

- **Excel**: лист «Записи» (дата, время, настроение, квадрант, заметка)
- **PDF день**: все записи + теги + заметки за один день
- **PDF период**: графики + корреляции + статистика

### `FileStorageService`

Загрузка медиа в Supabase Storage:
- Бакет `mood_photos` — фотографии
- Бакет `mood_voices` — голосовые сообщения
- `uploadPhoto(path)` / `uploadVoice(path)` → публичный URL
- `deleteFile(url)` — удаление из бакета

---

## 8. Синхронизация с Supabase

### Принцип офлайн-первый

1. Запись создаётся сразу в локальной SQLite
2. UI обновляется мгновенно
3. `SupabaseSyncService.syncAll()` работает в фоне

### Когда вызывается `syncAll()`

- При запуске приложения (`main.dart`)
- После успешного входа
- Когда появляется интернет (`connectivity_plus`)
- После сохранения записи (`health_step.dart`, `unawaited`)
- При обновление pull-to-refreshh

### Шаги `syncAll()`

Каждый шаг независим: ошибка в одном не блокирует остальные.

| Шаг | Метод | Таймаут |
|-----|-------|---------|
| 1 | `flushPendingDeletions()` | 10 сек |
| 2 | `_upload()` | 30 сек |
| 3 | `_download()` | 30 сек |
| 4 | `_syncAchievementsFromSupabase()` | 10 сек |
| 5 | `_syncAchievementsToSupabase()` | 10 сек |

### Очередь удалений

Если устройство офлайн при удалении записи — ID сохраняется в `SharedPreferences` (`pending_entry_deletions`). При следующем `syncAll()` список сбрасывается в Supabase.

---

## 9. Система ачивок

### Каталог (`kAchievements` в `achievement.dart`)

| ID | Название | Тип | Порог |
|----|----------|-----|-------|
| first_entry | Первый шаг | entry_count | 1 |
| streak_7 | Неделя | streak | 7 |
| streak_14 | Две недели | streak | 14 |
| streak_30 | Месяц | streak | 30 |
| streak_100 | 100 дней | streak | 100 |
| all_moods | Весь спектр | all_moods | — |

### Жизненный цикл

```
Первый запуск
  └── initAchievementsForUser() → 6 строк с isAchieved=false, synced=false

После каждого сохранения записи
  └── checkAfterEntrySaved()
        ├── getUnachievedAchievements()
        ├── calculateStreak()  ← использует date(created_at, 'unixepoch', 'localtime')
        ├── countMoodEntries()
        ├── hasAllMoodCategories()
        └── если условие → markAchievementAchieved(synced=false)
              ↓
            AchievementUnlockDialog (попап)
              ↓
            syncAll() → _syncAchievementsToSupabase() (synced → true)
```

---

## 10. Аналитика и графики

### 2D-пространство настроений

```
         +Y (Активное)
          ↑
 НегАкт   │   ПозАкт
──────────┼──────────→ +X (Позитивное)
 НегСпок  │   ПозСпок
          ↓
         -Y (Спокойное)
```

**Квадранты:**
- `negativeActive` — Ярость, Злость, Тревога, Напряжение
- `positiveActive` — Счастье, Эйфория, Воодушевление, Радость
- `negativeCalm` — Грусть, Печаль, Одиночество, Опустошение
- `positiveCalm` — Спокойствие, Гармония, Покой, Удовлетворение

### Виды графиков (fl_chart)

| График | Ось X | Ось Y | Период |
|--------|-------|-------|--------|
| Линейный (тренд) | Дата | avgX настроения | День / Неделя / Месяц / Год |
| Scatter внутри дня | Время суток | avgX | День |
| Календарь месяца | Число | — | Месяц |
| Столбцы по году | Месяц | Среднее | Год |
| Корреляция: сон | Часы сна | Настроение | Период |
| Корреляция: шаги | Тысячи шагов | Настроение | Период |
| Корреляция: погода | Категория темп. | Настроение | Период |
| Корреляция: цикл | Фаза | Настроение | Период |

---

## 11. Кризисный детектор

`CrisisDetector.detect(text)` анализирует текст заметки при сохранении.

**Уровни кризиса (`CrisisLevel`):**

| Уровень | Условие |
|---------|---------|
| `none` | Нет тревожных сигналов |
| `softStreak` | 3+ дней подряд с негативным настроением (avgX < 0) |
| `urgentStreak` | 7+ дней подряд с негативным настроением |
| `crisis` | Обнаружены ключевые слова |

**Ключевые слова (Уровень 1 — отдельные слова):**
суицид, умереть, повешусь, отравлюсь, порежусь и другие (19 триггеров)

**Ключевые фразы (Уровень 2 — комбинации):**
«ненавижу себя», «не хочу жить», «нет смысла жить» и другие (11 фраз)

При обнаружении `crisis` → показывается диалог с ресурсами помощи (горячая линия, кризисный центр). Диалог нельзя закрыть без подтверждения.

---

## 12. Здоровье и цикл

### Health API

На Android использует **Health Connect**, на iOS — **HealthKit**.

Права: `SLEEP_ASLEEP`, `STEPS`

Фоновая задача `step_sync_worker.dart` (WorkManager) запускается ежедневно в 23:30 и обновляет `health_data` для сегодняшнего дня автоматически.

### Менструальный цикл

**Настройки** (`CycleSettings`):
- `lastPeriodStart` — дата начала последней менструации
- `cycleLengthDays` — длина цикла (по умолчанию 28)
- `periodDurationDays` — длительность менструации (по умолчанию 5)

Фаза вычисляется для даты записи, отображается в `HealthContent` если пользователь — женщина с настроенным циклом.

---

## 13. Уведомления

Реализованы через **Firebase Cloud Messaging (FCM)** + локальные уведомления.

**Поток:**
1. При запуске `NotificationService.init()` запрашивает разрешение и получает FCM-токен
2. Токен + настройки (час, минута, enabled) сохраняются в таблицу `push_tokens` в Supabase
3. Supabase Edge Functions читают `push_tokens` и отправляют FCM-уведомление в заданное время

Пользователь может изменить время в `ProfileScreen` → сохраняется через `NotificationService.saveNotificationSettings()`.

---

## 14. Экспорт данных

Из `AnalyticsScreen` доступны:

- **Excel** — все записи за выбранный период в таблице
- **PDF (день)** — подробный отчёт за один день: настроения, теги, заметки, здоровье, погода
- **PDF (период)** — сводный отчёт: графики, статистика, корреляции
- **PDF (месяц)** — разбивка по квадрантам + типы дней

Файлы создаются синхронно (может зависнуть UI при больших данных) и предлагаются к шарингу через `share_plus`.

---

## 15. Зависимости

### Основные

| Пакет | Назначение |
|-------|-----------|
| `supabase_flutter ^2.0.0` | Бэкенд (БД + Auth + Storage) |
| `firebase_core ^3.0.0` | Firebase инициализация |
| `firebase_messaging ^15.0.0` | Push-уведомления FCM |
| `drift ^2.15.0` | ORM для SQLite |
| `provider ^6.1.5` | DI и управление состоянием |
| `health ^11.0.0` | Health Connect / HealthKit |
| `fl_chart ^0.69.0` | Графики |
| `flutter_svg ^2.0.9` | SVG-иконки |
| `excel ^4.0.6` | Excel-экспорт |
| `pdf ^3.11.1` | PDF-экспорт |
| `flutter_sound ^9.2.13` | Запись голоса |
| `workmanager ^0.9.0` | Фоновые задачи |
| `connectivity_plus ^6.0.3` | Определение сети |
| `shared_preferences ^2.3.0` | Настройки пользователя |
| `image_picker ^1.0.7` | Выбор фото |
| `geolocator ^10.1.0` | Геолокация |
| `app_links ^6.0.0` | Deep links |

### Dev

| Пакет | Назначение |
|-------|-----------|
| `drift_dev ^2.15.0` | Генерация кода Drift |
| `build_runner ^2.4.8` | Запуск кодогенерации |
| `flutter_launcher_icons ^0.14.3` | Иконка приложения |

---

## 16. Запуск проекта

### Требования

- Flutter 3.9.2+
- Android SDK, minSdkVersion 21 (Android 5.0+)
- Dart 3.x

### Установка

```bash
flutter pub get
```

### Кодогенерация (Drift)

После изменения схемы БД или таблиц:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Запуск

```bash
flutter run
```

### Отладочные логи

В консоли (`flutter run` или Logcat) ищи префиксы:
- `[Streak]` — расчёт стрика ачивок
- `[Achievements]` — проверка и разблокировка ачивок
- `[Sync]` — синхронизация с Supabase
- `[Crisis]` — срабатывание кризисного детектора

### Генерация тестовых данных

В `FakeDataGenerator` можно сгенерировать данные для разработки и тестирования UI.

---

## Технические решения

| Проблема | Решение |
|----------|---------|
| Данные нужны сразу без сети | SQLite (офлайн-первый) + фоновый sync |
| Стрик не считался (все даты = 1970) | `created_at` хранится в Unix-секундах; убран `/ 1000` в raw SQL |
| Sync падал на одном шаге и блокировал остальные | Каждый шаг `syncAll()` обёрнут в независимый try-catch |
| UI зависал при чтении `context.read` после await | Все Provider-зависимости захватываются до первого `await` |
| Теги исчезали при Hot Reload | Futures кешируются в `initState`, переинициализируются при удалении тега |
