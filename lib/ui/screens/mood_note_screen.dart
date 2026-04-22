import 'package:mindall/ui/app_route.dart';
// mood_note_screen.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart'; // 👈 для записи
import 'package:just_audio/just_audio.dart'; // 👈 для воспроизведения
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindall/ui/screens/weather_step.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/models/mood_entry_draft.dart';
import '../widgets/step_indicator.dart';
import '../widgets/bottom_button.dart';
import '../widgets/voice_player.dart';

class MoodNoteScreen extends StatefulWidget {
  final MoodEntryDraft draft;
  final String moodName;
  final Color moodColor;

  const MoodNoteScreen({
    super.key,
    required this.draft,
    required this.moodName,
    required this.moodColor,
  });

  @override
  State<MoodNoteScreen> createState() => _MoodNoteScreenState();
}

class _MoodNoteScreenState extends State<MoodNoteScreen> {
  late MoodEntryDraft _draft;
  final _textController = TextEditingController();

  // Для записи используем FlutterSoundRecorder
  final _recorder = FlutterSoundRecorder(); // 👈 ВЕРНУЛИ!

  // // Для воспроизведения используем just_audio
  // final _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;

    _recorder.openRecorder(); // 👈 открываем рекордер

    if (_draft.note.isNotEmpty) {
      _textController.text = _draft.note;
    }
  }

  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(toFile: path);

    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecorder();
    _recordingTimer?.cancel();
    _recordingTimer = null;

    setState(() {
      _isRecording = false;
      _recordingPath = path;
      _draft = _draft.copyWith(recordPath: path);
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _stopRecording();
      return;
    }

    final status = await Permission.microphone.request();

    if (status.isGranted) {
      _startRecording();
    } else if (status.isPermanentlyDenied) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Нет доступа к микрофону',
            style: TextStyle(color: Colors.white, fontFamily: 'DotGothic'),
          ),
          content: const Text(
            'Разреши доступ к микрофону в настройках телефона.',
            style: TextStyle(color: Color(0xFFC0C0C0), fontFamily: 'DotGothic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Настройки', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _deleteRecording() {
    setState(() {
      _recordingPath = null;
      _recordingDuration = Duration.zero;
      _draft = _draft.copyWith(recordPath: null);
    });
  }




  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.closeRecorder(); // 👈 закрываем рекордер
    super.dispose();
  }

  Future<void> _pickImageWithChoice() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  'Сделать фото',
                  style: TextStyle(
                    fontFamily: 'DotGothic',
                    color: Colors.white,
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.white),
                title: const Text(
                  'Выбрать из галереи',
                  style: TextStyle(
                    fontFamily: 'DotGothic',
                    color: Colors.white,
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (file != null && mounted) {
      setState(() {
        _draft = _draft.copyWith(
          imagePaths: [..._draft.imagePaths, file.path],
        );
      });
    }
  }

  void _saveAndContinue() {
    _draft = _draft.copyWith(note: _textController.text);
    _goToWeather();
  }

  void _goToWeather() {
    Navigator.push(
      context,
      AppRoute(page: WeatherStepScreen(
          draft: _draft,
          moodColor: widget.moodColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth - 48;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _draft),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _Header(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          /// Текстовая заметка
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF555555),
                                width: 2,
                              ),
                            ),
                            child: TextField(
                              controller: _textController,
                              onChanged: (value) {
                                setState(() {
                                  _draft = _draft.copyWith(note: value);
                                });
                              },
                              maxLines: 6,
                              cursorColor: widget.moodColor,
                              style: const TextStyle(
                                fontFamily: 'DotGothic',
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Опиши, что произошло...',
                                hintStyle: TextStyle(
                                  fontFamily: 'DotGothic',
                                  color: Color(0xFF777777),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// Индикатор записи
                          if (_isRecording)
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const _RecordingDot(),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDuration(_recordingDuration),
                                      style: const TextStyle(
                                        fontFamily: 'DotGothic',
                                        fontSize: 16,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          /// Плеер для готовой записи
                          if (_recordingPath != null && !_isRecording)
                            VoicePlayerWidget(
                              filePath: _recordingPath!,
                              accentColor: widget.moodColor,
                              onDelete: _deleteRecording,
                            ),

                          /// Кнопки медиа
                          Row(
                            children: [
                              _MediaButton(
                                icon: SvgPicture.asset(
                                  'lib/ui/assets/pixelariticons_svg/camera-add.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onTap: _pickImageWithChoice,
                              ),
                              const SizedBox(width: 16),
                              _MediaButton(
                                icon: _isRecording
                                    ? Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                )
                                    : SvgPicture.asset(
                                  'lib/ui/assets/pixelariticons_svg/micro.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onTap: _toggleRecording,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// Фотки
                          if (_draft.imagePaths.isNotEmpty)
                            SizedBox(
                              height: imageSize,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _draft.imagePaths.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final path = _draft.imagePaths[index];

                                  return Stack(
                                    children: [
                                      Container(
                                        width: imageSize,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFF555555),
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          child: Image.file(
                                            File(path),
                                            fit: BoxFit.cover,
                                            width: imageSize,
                                            height: imageSize,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              final updated = [..._draft.imagePaths]
                                                ..removeAt(index);
                                              _draft = _draft.copyWith(imagePaths: updated);
                                            });
                                          },
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Кнопка "Далее"
          BottomButton(
            text: 'Далее',
            color: widget.moodColor,
            onTap: _saveAndContinue,
          ),
        ],
      ),
    );
  }

  Widget _Header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          StepIndicator(currentStep: 1),
          const SizedBox(height: 24),
          const Text(
            'Хочешь что-нибудь\nзаписать?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.moodName,
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 22,
              color: widget.moodColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;

  const _MediaButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF555555),
            width: 2,
          ),
        ),
        child: icon,
      ),
    );
  }
}

class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(_controller.value * 0.7 + 0.3),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(_controller.value * 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}