// auth_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindall/ui/app_route.dart';
import 'package:mindall/ui/screens/policy_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/subscription_service.dart';
import '../../domain/services/user_profile_service.dart';
import 'main_nav_scaffold.dart';

const _accentGreen = Color(0xFF83F483);
const _accentYellow = Color(0xFFFFEB89);
const _accentPurple = Color(0xFF9B7BFF);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _acceptedPolicy = false;
  bool _isLogin = true;
  bool _loading = false;
  bool _registered = false;
  String? _error;
  Gender? _gender;
  String _email = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Заполни все поля');
      return;
    }
    if (!_isLogin) {
      if (username.isEmpty) {
        setState(() => _error = 'Введи имя');
        return;
      }
      if (_gender == null) {
        setState(() => _error = 'Выбери пол');
        return;
      }
      if (!_acceptedPolicy) {
        setState(() => _error = 'Прими условия политики конфиденциальности');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
      _email = email;
    });

    try {
      final supabase = Supabase.instance.client;
      final profileService = context.read<UserProfileService>();
      final subscriptionService = context.read<SubscriptionService>();

      const timeout = Duration(seconds: 5);
      if (_isLogin) {
        await supabase.auth
            .signInWithPassword(email: email, password: password)
            .timeout(timeout);
        TextInput.finishAutofillContext(shouldSave: true);

        final user = supabase.auth.currentUser!;
        await profileService.syncFromSupabase(user.id);
        await subscriptionService.syncFromRemote(user);

        await NotificationService().loadSettingsFromRemote();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            AppRoute(page: const MainNavScaffold()),
                (_) => false,
          );
        }
      } else {
        final response = await supabase.auth
            .signUp(
          email: email,
          password: password,
          emailRedirectTo: 'mindall://email-confirm',
          data: {'username': username, 'gender': _gender!.name},
        )
            .timeout(timeout);

        if (response.session != null && response.user != null) {
          await _saveProfile(
            response.user!.id,
            username,
            _gender!,
            profileService,
          );

          await profileService.syncFromSupabase(response.user!.id);
          await subscriptionService.syncFromRemote(response.user!);

          TextInput.finishAutofillContext(shouldSave: true);
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              AppRoute(page: const MainNavScaffold()),
                  (_) => false,
            );
          }
        } else {
          if (mounted) setState(() => _registered = true);
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = _mapError(e.message));
    } catch (_) {
      setState(() => _error = 'Проверьте подключение к интернету или VPN');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile(
      String userId,
      String username,
      Gender gender,
      UserProfileService profileService,
      ) async {
    await Supabase.instance.client.from('profiles').upsert({
      'user_id': userId,
      'username': username,
      'gender': gender.name,
      'subscription_type': SubscriptionType.premium.name,
    });
    await profileService.saveUsername(username);
    await profileService.saveGender(gender);
    await profileService.saveSubscriptionType(SubscriptionType.premium);
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Введи email выше');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(email, redirectTo: 'mindall://reset-password')
          .timeout(const Duration(seconds: 10));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Письмо со сбросом пароля отправлено')),
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = _mapError(e.message));
    } on TimeoutException {
      setState(() => _error = 'Сервер не отвечает — попробуй позже');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('network')) {
        setState(() => _error = 'Проверьте подключение к интернету');
      } else {
        setState(() => _error = _mapError(msg));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapError(String message) {
    if (message.contains('Invalid login credentials'))
      return 'Неверный email или пароль';
    if (message.contains('Email not confirmed'))
      return 'Подтверди email — письмо отправлено';
    if (message.contains('User already registered'))
      return 'Этот email уже зарегистрирован';
    if (message.contains('Password should be')) return 'Пароль минимум 6 символов';
    if (message.contains('security purposes') || message.contains('after'))
      return 'Подожди немного перед повторной отправкой';
    if (message.contains('rate') || message.contains('limit'))
      return 'Слишком много попыток — подожди';
    return message.isNotEmpty
        ? message
        : 'Проверьте подключение к интернету или VPN';
  }

  Widget _emailSentScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Text(
                'Проверь\nпочту',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DotGothic',
                  fontSize: 32,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'На $_email отправлено письмо с подтверждением.\nПерейди по ссылке и вернись.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DotGothic',
                  fontSize: 14,
                  color: Colors.white54,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 56),
              GestureDetector(
                onTap: () => setState(() {
                  _registered = false;
                  _isLogin = true;
                }),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      'войти',
                      style: TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_registered) return _emailSentScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),

              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: 'DotGothic',
                    fontSize: 32,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  children: _isLogin
                      ? [
                    const TextSpan(text: 'Привет,\n'),
                    TextSpan(
                      text: 'снова ты',
                      style: TextStyle(color: _accentGreen),
                    ),
                  ]
                      : [
                    const TextSpan(text: 'Создать\n'),
                    TextSpan(
                      text: 'аккаунт',
                      style: TextStyle(color: _accentYellow),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              if (!_isLogin) ...[
                _PixelField(controller: _usernameController, hint: 'имя'),
                const SizedBox(height: 24),
                const Text(
                  'ПОЛ',
                  style: TextStyle(
                    fontFamily: 'DotGothic',
                    fontSize: 11,
                    color: Colors.white38,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _GenderButton(
                      label: 'женщина',
                      selected: _gender == Gender.female,
                      accent: _accentPurple,
                      onTap: () => setState(() => _gender = Gender.female),
                    ),
                    const SizedBox(width: 8),
                    _GenderButton(
                      label: 'мужчина',
                      selected: _gender == Gender.male,
                      accent: _accentGreen,
                      onTap: () => setState(() => _gender = Gender.male),
                    ),
                    const SizedBox(width: 8),
                    _GenderButton(
                      label: '—',
                      selected: _gender == Gender.preferNotToSay,
                      accent: Colors.white,
                      onTap: () => setState(() => _gender = Gender.preferNotToSay),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              AutofillGroup(
                child: Column(
                  children: [
                    _PixelField(
                      controller: _emailController,
                      hint: 'email',
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 16),
                    _PixelField(
                      controller: _passwordController,
                      hint: 'пароль',
                      obscure: true,
                      autofillHints: _isLogin
                          ? const [AutofillHints.password]
                          : const [AutofillHints.newPassword],
                    ),
                  ],
                ),
              ),

              if (_isLogin) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _loading ? null : _forgotPassword,
                    child: const Text(
                      'забыл пароль?',
                      style: TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'DotGothic',
                    color: Color(0xFFFF6B6B),
                    fontSize: 13,
                  ),
                ),

              const SizedBox(height: 20),

              if (!_isLogin) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _acceptedPolicy,
                        onChanged: (val) => setState(() => _acceptedPolicy = val ?? false),
                        activeColor: _accentGreen,
                        checkColor: Colors.black,
                        side: const BorderSide(color: Colors.white38),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'DotGothic',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          children: [
                            const TextSpan(text: 'Я принимаю '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: _showPrivacyPolicy,
                                child: Text(
                                  'политику конфиденциальности',
                                  style: TextStyle(
                                    color: _accentYellow,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' и соглашаюсь с обработкой данных.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Разработчик не несёт ответственности за использование приложения не по назначению или в нарушение законодательства.',
                  style: TextStyle(
                    fontFamily: 'DotGothic',
                    fontSize: 10,
                    color: Colors.white38,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),

              GestureDetector(
                onTap: _loading ? null : _submit,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      _isLogin ? 'войти' : 'зарегистрироваться',
                      style: const TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => setState(() {
                  _isLogin = !_isLogin;
                  _error = null;
                  _gender = null;
                  _acceptedPolicy = false;
                }),
                child: Text.rich(
                  _isLogin
                      ? TextSpan(
                    children: [
                      const TextSpan(
                        text: 'нет аккаунта? ',
                        style: TextStyle(color: Colors.white38),
                      ),
                      TextSpan(
                        text: 'создать',
                        style: TextStyle(color: _accentYellow),
                      ),
                    ],
                  )
                      : TextSpan(
                    children: [
                      const TextSpan(
                        text: 'уже есть аккаунт? ',
                        style: TextStyle(color: Colors.white38),
                      ),
                      TextSpan(
                        text: 'войти',
                        style: TextStyle(color: _accentGreen),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontFamily: 'DotGothic', fontSize: 13),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _PixelField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final List<String>? autofillHints;

  const _PixelField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: const TextStyle(
        fontFamily: 'DotGothic',
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'DotGothic',
          color: Colors.white54,
          fontSize: 16,
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

class _GenderButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? accent : Colors.white24),
          color: selected ? accent.withOpacity(0.12) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 13,
            color: selected ? accent : Colors.white38,
          ),
        ),
      ),
    );
  }
}