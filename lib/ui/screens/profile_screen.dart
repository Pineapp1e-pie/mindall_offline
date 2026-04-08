import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/user_profile_service.dart';
import 'auth_screen.dart';
import 'cycle_setup_screen.dart';

const _accentGreen  = Color(0xFF83F483);
const _accentYellow = Color(0xFFFFEB89);
const _accentPurple = Color(0xFF9B7BFF);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = UserProfileService();
  final _client = Supabase.instance.client;

  String _username = '';
  String _email = '';
  Gender? _gender;
  CycleSettings? _cycleSettings;
  bool _trackCycle = false;
  bool _loading = true;

  bool _notifEnabled = false;
  int _notifHour = 18;
  int _notifMinute = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _email = user.email ?? '';

    // Сначала показываем локальный кеш — без сети
    final localProfile = await _profileService.load();
    if (localProfile != null) {
      _username = localProfile.username ?? '';
      _gender = localProfile.gender;
      _cycleSettings = localProfile.cycleSettings;
      _trackCycle = localProfile.cycleSettings != null;
    }

    _notifEnabled = await _profileService.loadNotificationsEnabled();
    _notifHour = await _profileService.loadNotificationHour();
    _notifMinute = await _profileService.loadNotificationMinute();

    if (mounted) setState(() => _loading = false);

    // Фоном синхронизируем с Supabase
    _syncFromRemote(user);
  }

  Future<void> _syncFromRemote(User user) async {
    final profile = await _client
        .from('profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    String? newUsername;
    Gender? newGender;

    if (profile != null) {
      newUsername = profile['username'] as String? ?? '';
      final genderStr = profile['gender'] as String?;
      if (genderStr != null) {
        newGender = Gender.values.firstWhere(
          (g) => g.name == genderStr,
          orElse: () => Gender.preferNotToSay,
        );
      }
    } else {
      // Профиля нет — читаем из userMetadata и создаём запись
      final meta = user.userMetadata;
      if (meta != null) {
        newUsername = meta['username'] as String? ?? '';
        final genderStr = meta['gender'] as String?;
        if (genderStr != null) {
          newGender = Gender.values.firstWhere(
            (g) => g.name == genderStr,
            orElse: () => Gender.preferNotToSay,
          );
        }
        await _client.from('profiles').upsert({
          'user_id': user.id,
          'username': newUsername,
          'gender': newGender?.name,
        });
      }
    }

    // Сохраняем в кеш
    if (newUsername != null) await _profileService.saveUsername(newUsername);
    if (newGender != null) await _profileService.saveGender(newGender);

    // Обновляем UI если данные изменились
    if (mounted) {
      setState(() {
        if (newUsername != null) _username = newUsername!;
        if (newGender != null) _gender = newGender;
      });
    }
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

    await _client.from('profiles').upsert({
      'user_id': _client.auth.currentUser!.id,
      'username': result.trim(),
    });
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
    await _client.from('profiles').upsert({
      'user_id': _client.auth.currentUser!.id,
      'gender': result.name,
    });
  }

  // ──────────────────────────────────────
  // Диалог смены пароля
  // ──────────────────────────────────────

  Future<void> _changePassword() async {
    final result = await showDialog<_PasswordResult>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (result == null) return;

    try {
      // Проверяем старый пароль через повторный вход
      await _client.auth.signInWithPassword(
        email: _email,
        password: result.oldPassword,
      );
      // Меняем пароль
      await _client.auth.updateUser(UserAttributes(password: result.newPassword));
      TextInput.finishAutofillContext(shouldSave: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароль обновлён')),
        );
      }
    } on AuthException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный текущий пароль')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Проверьте подключение к интернету или VPN')),
        );
      }
    }
  }

  // ──────────────────────────────────────
  // Удаление аккаунта
  // ──────────────────────────────────────

  Future<void> _deleteAccount() async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF18221C),
        title: const Text(
          'Удалить аккаунт?',
          style: TextStyle(fontFamily: 'DotGothic', color: Colors.white),
        ),
        content: const Text(
          'Все данные будут удалены. Это действие нельзя отменить.',
          style: TextStyle(fontFamily: 'DotGothic', color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
    if (confirm1 != true) return;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF18221C),
        title: const Text(
          'Точно удалить?',
          style: TextStyle(fontFamily: 'DotGothic', color: Color(0xFFFF6B6B)),
        ),
        content: const Text(
          'Восстановить аккаунт будет невозможно.',
          style: TextStyle(fontFamily: 'DotGothic', color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да, удалить', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
    if (confirm2 != true) return;

    await _client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }

  // ──────────────────────────────────────
  // Выход
  // ──────────────────────────────────────

  Future<void> _signOut() async {
    await _client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }

  // ──────────────────────────────────────
  // Настройки цикла
  // ──────────────────────────────────────

  Future<void> _openCycleSetup() async {
    final result = await Navigator.push<CycleSettings>(
      context,
      MaterialPageRoute(
        builder: (_) => CycleSetupScreen(
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

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService().requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Разреши уведомления в настройках телефона',
                style: TextStyle(fontFamily: 'DotGothic'),
              ),
            ),
          );
        }
        return;
      }
      await NotificationService().scheduleDailyReminder(_notifHour, _notifMinute);
    } else {
      await NotificationService().cancelReminder();
    }
    setState(() => _notifEnabled = value);
    await _profileService.saveNotificationSettings(value, _notifHour, _notifMinute);
  }

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
    await NotificationService().scheduleDailyReminder(_notifHour, _notifMinute);
    await _profileService.saveNotificationSettings(_notifEnabled, _notifHour, _notifMinute);
  }

  String _genderLabel(Gender? gender) {
    switch (gender) {
      case Gender.female: return 'женщина';
      case Gender.male: return 'мужчина';
      case Gender.preferNotToSay: return 'не указан';
      case null: return 'не указан';
    }
  }

  Future<void> _toggleCycle(bool value) async {
    setState(() => _trackCycle = value);
    if (value && _cycleSettings == null) {
      await _openCycleSetup();
    }
    if (!value) {
      setState(() => _cycleSettings = null);
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
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: const TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 13,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),

            // ── Достигнутые ачивки ─────────────────
            _SectionLabel('достижения', color: _accentGreen),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: const [
                  _AchievementCard(label: '7 дней', icon: Icons.local_fire_department, earned: true, color: _accentYellow),
                  _AchievementCard(label: 'первая запись', icon: Icons.edit, earned: true, color: _accentGreen),
                  _AchievementCard(label: '30 дней', icon: Icons.star, earned: false, color: _accentYellow),
                  _AchievementCard(label: '100 записей', icon: Icons.bar_chart, earned: false, color: _accentPurple),
                  _AchievementCard(label: 'ранняя птица', icon: Icons.wb_sunny, earned: false, color: _accentGreen),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Редактировать профиль ───────────────
            _SectionLabel('редактировать профиль', color: _accentYellow),
            _SettingRow(
              label: 'имя',
              value: _username,
              onTap: _editUsername,
            ),
            _SettingRow(
              label: 'пол',
              value: _genderLabel(_gender),
              onTap: _editGender,
            ),
            _SettingRow(
              label: 'почта',
              value: _email,
            ),
            _SettingRow(
              label: 'пароль',
              value: '••••••',
              onTap: _changePassword,
            ),

            const SizedBox(height: 24),

            // ── Настройки ──────────────────────────
            _SectionLabel('настройки', color: _accentGreen),
            _SettingRow(
              label: 'тариф',
              value: 'бесплатный',
            ),
            _SettingRow(
              label: 'уведомления',
              trailing: Switch(
                value: _notifEnabled,
                onChanged: _toggleNotifications,
                activeColor: Colors.white,
                inactiveThumbColor: Colors.white24,
                inactiveTrackColor: Colors.white12,
              ),
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
                _SettingRow(
                  label: 'настройки цикла',
                  onTap: _openCycleSetup,
                ),
            ],

            const SizedBox(height: 24),

            // ── Аккаунт ────────────────────────────
            _SectionLabel('аккаунт', color: Color(0xFFFF6B6B)),
            _SettingRow(
              label: 'удалить аккаунт',
              labelColor: const Color(0xFFFF6B6B),
              onTap: _deleteAccount,
            ),
            _SettingRow(
              label: 'выйти',
              onTap: _signOut,
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
                    const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool earned;
  final Color color;

  const _AchievementCard({
    required this.label,
    required this.icon,
    required this.earned,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: earned ? color : Colors.white12,
        ),
        color: earned ? color.withOpacity(0.08) : Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: earned ? color : Colors.white24,
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 10,
              color: earned ? color : Colors.white24,
            ),
          ),
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
        style: const TextStyle(fontFamily: 'DotGothic', color: Colors.white, fontSize: 16),
      ),
      content: TextField(
        controller: controller,
        obscureText: obscure,
        autofocus: true,
        style: const TextStyle(fontFamily: 'DotGothic', color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontFamily: 'DotGothic'),
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
        style: TextStyle(fontFamily: 'DotGothic', color: Colors.white, fontSize: 16),
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
        style: TextStyle(fontFamily: 'DotGothic', color: Colors.white, fontSize: 16),
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
      style: const TextStyle(fontFamily: 'DotGothic', color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontFamily: 'DotGothic', fontSize: 14),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),
    );
  }
}
