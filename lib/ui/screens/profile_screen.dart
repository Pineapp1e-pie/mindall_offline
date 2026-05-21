import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/local/repositories/local_repository.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/subscription_service.dart';
import '../../domain/services/user_profile_service.dart';
import '../app_route.dart';
import '../widgets/achievement_popup.dart';
import 'onboarding_screen.dart';
import 'cycle_setup_screen.dart';

const _accentGreen = Color(0xFF83F483);
const _accentYellow = Color(0xFFFFEB89);
const _accentPurple = Color(0xFF9B7BFF);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfileService _profileService;

  String _username = '';
  Gender? _gender;
  CycleSettings? _cycleSettings;
  bool _trackCycle = false;
  bool _loading = true;

  bool _notifEnabled = false;
  int _notifHour = 18;
  int _notifMinute = 0;

  List<Achievement> _achievements = kAchievements.toList();

  @override
  void initState() {
    super.initState();
    _profileService = context.read<UserProfileService>();
    _load();
  }

  Future<void> _load() async {
    _username = _profileService.username ?? '';
    _gender = _profileService.gender;
    _cycleSettings = _profileService.cycleSettings;
    _trackCycle = _profileService.cycleSettings != null;

    _notifEnabled = await _profileService.loadNotificationsEnabled();
    _notifHour = await _profileService.loadNotificationHour();
    _notifMinute = await _profileService.loadNotificationMinute();

    await _loadAchievements('local_user');

    if (mounted) setState(() => _loading = false);


  }

  Future<void> _loadAchievements(String userId) async {
    final repo = context.read<LocalRepository>();
    final dbRows = await repo.getAllAchievements(userId);
    if (!mounted) return;
    setState(() {
      _achievements = kAchievements.map((catalog) {
        final row = dbRows
            .where((r) => r.achievementId == catalog.id)
            .firstOrNull;
        if (row == null) return catalog;
        return catalog.copyWith(
          isAchieved: row.isAchieved,
          achievedAt: row.achievedAt,
          synced: row.synced,
        );
      }).toList();
    });
  }



  // ──────────────────────────────────────
  // Диалог редактирования имени
  // ──────────────────────────────────────

  Future<void> _editUsername() async {
    final ctrl = TextEditingController(text: _username);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditDialog(title: 'Имя', controller: ctrl),
    );
    if (result == null || result.trim().isEmpty) return;

    await _profileService.saveUsername(result.trim());
    setState(() => _username = result.trim());
  }

  // ──────────────────────────────────────
  // Диалог редактирования пола
  // ──────────────────────────────────────

  Future<void> _editGender() async {
    final result = await showDialog<Gender>(
      context: context,
      builder: (_) => _GenderDialog(current: _gender),
    );
    if (result == null) return;

    setState(() => _gender = result);
    await _profileService.saveGender(result);
  }

  Future<void> _resetApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF18221C),
        title: const Text(
          'Сбросить приложение?',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'DotGothic',
          ),
        ),
        content: const Text(
          'Все локальные данные будут удалены.',
          style: TextStyle(
            color: Colors.white70,
            fontFamily: 'DotGothic',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _profileService.clearAll();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
          (_) => false,
    );
  }

  // ──────────────────────────────────────
  // Настройки цикла
  // ──────────────────────────────────────

  Future<void> _openCycleSetup() async {
    final result = await Navigator.push<CycleSettings>(
      context,
      AppRoute(
        page: CycleSetupScreen(
          moodColor: Colors.white,
          initial: _cycleSettings,
        ),
      ),
    );
    if (result != null) setState(() => _cycleSettings = result);
  }

  // ──────────────────────────────────────
  // Уведомления
  // ──────────────────────────────────────

  // Future<void> _toggleNotifications(bool value) async {
  //   if (value) {
  //     //final granted = await NotificationService().requestPermission();
  //     if (!granted) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text(
  //               'Разреши уведомления в настройках телефона',
  //               style: TextStyle(fontFamily: 'DotGothic'),
  //             ),
  //           ),
  //         );
  //       }
  //       return;
  //     }
  //   }
  //   setState(() => _notifEnabled = value);
  //   await _profileService.saveNotificationSettings(
  //     value,
  //     _notifHour,
  //     _notifMinute,
  //   );
  //   // await NotificationService().saveNotificationSettings(
  //   //   enabled: value,
  //   //   hour: _notifHour,
  //   //   minute: _notifMinute,
  //   // );
  // }


  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notifHour, minute: _notifMinute),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Color(0xFF0E1511),
            surface: Color(0xFF18221C),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    setState(() {
      _notifHour = picked.hour;
      _notifMinute = picked.minute;
    });
    await _profileService.saveNotificationSettings(
      _notifEnabled,
      _notifHour,
      _notifMinute,
    );
    //
    // final online = await _hasInternet();
    // if (!online) {
    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text(
    //           'Уведомления работают только при наличии интернета',
    //           style: TextStyle(fontFamily: 'DotGothic'),
    //         ),
    //       ),
    //     );
    //   }
    //   return;
    // }

    // await NotificationService().saveNotificationSettings(
    //   enabled: _notifEnabled,
    //   hour: _notifHour,
    //   minute: _notifMinute,
    // );
  }

  String _genderLabel(Gender? gender) {
    switch (gender) {
      case Gender.female:
        return 'женщина';
      case Gender.male:
        return 'мужчина';
      case Gender.preferNotToSay:
        return 'не указан';
      case null:
        return 'не указан';
    }
  }

  String _subscriptionLabel(SubscriptionType type) {
    return switch (type) {
      SubscriptionType.free => 'Бесплатный',
      SubscriptionType.premium => 'Premium',
    };
  }

  Future<void> _showSubscriptionDialog() async {
    final shouldToggle = await showDialog<bool>(
      context: context,
      builder: (_) => const _SubscriptionDialog(),
    );
    if (shouldToggle != true || !mounted) return;

    await context.read<SubscriptionService>().toggleSubscription();
    if (!mounted) return;

    final type = context.read<SubscriptionService>().type;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Тариф изменён: ${_subscriptionLabel(type)}',
          style: const TextStyle(fontFamily: 'DotGothic'),
        ),
      ),
    );
  }

  Future<void> _toggleCycle(bool value) async {
    setState(() => _trackCycle = value);
    if (value && _cycleSettings == null) {
      await _openCycleSetup();
    }
    if (!value) {
      setState(() => _cycleSettings = null);
      await _profileService.clearCycleSettings();
    }
  }

  // ──────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E1511),
        body: Center(child: CircularProgressIndicator(color: Colors.white24)),
      );
    }

    final isFemale = _gender == Gender.female;
    final subscription = context.watch<SubscriptionService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Профиль',
          style: TextStyle(
            fontFamily: 'DotGothic',
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Шапка ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _username.isEmpty ? 'Пользователь' : _username,
                    style: const TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 26,
                      color: _accentYellow,
                    ),
                  ),

                ],
              ),
            ),

            // ── Достижения ─────────────────────────
            _SectionLabel('достижения', color: _accentGreen),
            const SizedBox(height: 16),
            SizedBox(
              height: 148,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _achievements.length,
                itemBuilder: (context, i) =>
                    _AchievementCard(achievement: _achievements[i]),
              ),
            ),

            const SizedBox(height: 32),

            // ── Редактировать профиль ───────────────
            _SectionLabel('редактировать профиль', color: _accentYellow),
            _SettingRow(label: 'имя', value: _username, onTap: _editUsername),
            _SettingRow(
              label: 'пол',
              value: _genderLabel(_gender),
              onTap: _editGender,
            ),

            const SizedBox(height: 24),

            // ── Настройки ──────────────────────────
            _SectionLabel('настройки', color: _accentGreen),
            _SettingRow(
              label: 'тариф',
              value: _subscriptionLabel(subscription.type),
            ),
            _SettingRow(label: 'сменить тариф', onTap: _showSubscriptionDialog),
            _SettingRow(
              label: 'уведомления',
              // trailing: Switch(
              //   value: _notifEnabled,
              //   // onChanged: _toggleNotifications,
              //   activeColor: Colors.white,
              //   inactiveThumbColor: Colors.white24,
              //   inactiveTrackColor: Colors.white12,
              // ),
            ),
            if (_notifEnabled)
              _SettingRow(
                label: 'время',
                value:
                    '${_notifHour.toString().padLeft(2, '0')}:${_notifMinute.toString().padLeft(2, '0')}',
                onTap: _pickNotificationTime,
              ),

            // ── Цикл (только для женщин) ───────────
            if (isFemale) ...[
              const SizedBox(height: 24),
              _SectionLabel('цикл', color: _accentPurple),
              _SettingRow(
                label: 'отслеживать цикл',
                trailing: Switch(
                  value: _trackCycle,
                  onChanged: _toggleCycle,
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.white24,
                  inactiveTrackColor: Colors.white12,
                ),
              ),
              if (_trackCycle)
                _SettingRow(label: 'настройки цикла', onTap: _openCycleSetup),
            ],

            const SizedBox(height: 24),

            // ── Аккаунт ────────────────────────────
            _SectionLabel('аккаунт', color: Color(0xFFFF6B6B)),
            _SettingRow(
              label: 'удалить все данные',
              labelColor: const Color(0xFFFF6B6B),
              onTap: _resetApp,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}



// ──────────────────────────────────────
// Виджеты
// ──────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, {this.color = Colors.white38});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Row(
        children: [
          Container(width: 3, height: 12, color: color),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 11,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color labelColor;

  const _SettingRow({
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.labelColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 15,
                color: labelColor,
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Row(
                children: [
                  if (value != null)
                    Text(
                      value!,
                      style: const TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 13,
                        color: Colors.white38,
                      ),
                    ),
                  if (onTap != null) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white24,
                      size: 18,
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

const _moodPalette = [
  Color(0xFFFF5959),
  Color(0xFFFF7979),
  Color(0xFFFFAEAE),
  Color(0xFF835AFF),
  Color(0xFF9B7BFF),
  Color(0xFFB8A1FF),
  Color(0xFF46FF46),
  Color(0xFF66FF66),
  Color(0xFF83F483),
  Color(0xFFFFDD3B),
  Color(0xFFFCE365),
  Color(0xFFFFEB89),
];

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final earned = achievement.isAchieved;
    final color = earned ? Colors.amber : Colors.white24;
    final borderColor = earned
        ? _moodPalette[Random(
            achievement.id.hashCode,
          ).nextInt(_moodPalette.length)]
        : Colors.white24;

    String? dateLabel;
    if (earned && achievement.achievedAt != null) {
      dateLabel = DateFormat('dd.MM.yy').format(achievement.achievedAt!);
    }

    return Container(
      width: 112,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          achievementIcon(achievement),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 11,
              color: color,
            ),
          ),
          if (dateLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              dateLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 9,
                color: Colors.white38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final bool obscure;
  final String? hint;

  const _EditDialog({
    required this.title,
    required this.controller,
    this.obscure = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF18221C),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'DotGothic',
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      content: TextField(
        controller: controller,
        obscureText: obscure,
        autofocus: true,
        style: const TextStyle(fontFamily: 'DotGothic', color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white24,
            fontFamily: 'DotGothic',
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена', style: TextStyle(color: Colors.white38)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _SubscriptionDialog extends StatelessWidget {
  const _SubscriptionDialog();

  static const _freeFeatures = [
    'запись настроения',
    'базовые графики',
    'заметки: текст, фото, голос',
  ];

  static const _premiumFeatures = [
    'погода и здоровье в записи',
    'корреляции: сон / шаги / погода / цикл',
    'расширенная аналитика',
    'автоматические данные здоровья через health connect',
    'детальные графики',
    'экспорт PDF / Excel',
  ];

  @override
  Widget build(BuildContext context) {
    final current = context.watch<SubscriptionService>().type;

    return AlertDialog(
      backgroundColor: const Color(0xFF18221C),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      title: const Text(
        'Сменить тариф?',
        style: TextStyle(
          fontFamily: 'DotGothic',
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlanColumn(
              title: 'FREE',
              features: _freeFeatures,
              accent: _accentGreen,
              active: current == SubscriptionType.free,
            ),
            const SizedBox(height: 10),
            _PlanColumn(
              title: 'PREMIUM',
              features: _premiumFeatures,
              accent: _accentYellow,
              active: current == SubscriptionType.premium,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена', style: TextStyle(color: Colors.white38)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            current == SubscriptionType.premium
                ? 'Перейти на FREE'
                : 'Перейти на Premium',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _PlanColumn extends StatelessWidget {
  final String title;
  final List<String> features;
  final Color accent;
  final bool active;

  const _PlanColumn({
    required this.title,
    required this.features,
    required this.accent,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: active ? accent : Colors.white24, width: 1.5),
        color: active ? Colors.white10 : Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active ? '$title · сейчас' : title,
            style: TextStyle(
              fontFamily: 'DotGothic',
              color: accent,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• $feature',
                style: const TextStyle(
                  fontFamily: 'DotGothic',
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────
// Диалог выбора пола
// ──────────────────────────────────────

class _GenderDialog extends StatefulWidget {
  final Gender? current;
  const _GenderDialog({this.current});

  @override
  State<_GenderDialog> createState() => _GenderDialogState();
}

class _GenderDialogState extends State<_GenderDialog> {
  late Gender? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF18221C),
      title: const Text(
        'Пол',
        style: TextStyle(
          fontFamily: 'DotGothic',
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(Gender.female, 'женщина'),
          _option(Gender.male, 'мужчина'),
          _option(Gender.preferNotToSay, 'не указывать'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена', style: TextStyle(color: Colors.white38)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _option(Gender gender, String label) {
    final selected = _selected == gender;
    return GestureDetector(
      onTap: () => setState(() => _selected = gender),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Colors.white : Colors.white24),
          color: selected ? Colors.white12 : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 14,
            color: selected ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────
// Диалог смены пароля
// ──────────────────────────────────────

class _PasswordResult {
  final String oldPassword;
  final String newPassword;
  const _PasswordResult(this.oldPassword, this.newPassword);
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final old = _oldCtrl.text.trim();
    final next = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (old.isEmpty || next.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Заполни все поля');
      return;
    }
    if (next.length < 6) {
      setState(() => _error = 'Минимум 6 символов');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }

    Navigator.pop(context, _PasswordResult(old, next));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF18221C),
      title: const Text(
        'Сменить пароль',
        style: TextStyle(
          fontFamily: 'DotGothic',
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      content: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_oldCtrl, 'текущий пароль', null),
            const SizedBox(height: 16),
            _field(_newCtrl, 'новый пароль', AutofillHints.newPassword),
            const SizedBox(height: 16),
            _field(_confirmCtrl, 'повтори новый', null),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'DotGothic',
                  color: Color(0xFFFF6B6B),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена', style: TextStyle(color: Colors.white38)),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String hint, String? autofillHint) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      autofillHints: autofillHint != null ? [autofillHint] : const [],
      style: const TextStyle(
        fontFamily: 'DotGothic',
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.white24,
          fontFamily: 'DotGothic',
          fontSize: 14,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}


