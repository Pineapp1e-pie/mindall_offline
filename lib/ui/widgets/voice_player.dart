
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class VoicePlayerWidget extends StatefulWidget {
  final String filePath;
  final Color accentColor;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;
  final VoidCallback? onDelete;

  const VoicePlayerWidget({
    super.key,
    required this.filePath,
    required this.accentColor,
    this.onPlay,
    this.onStop,
    this.onDelete,
  });

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoading = true;
  bool _isDragging = false;
  double _dragProgress = 0.0;

  // FIX: храним подписки, чтобы явно отписаться в dispose
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _player = AudioPlayer();

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    // Позиция
    _subscriptions.add(
      _player.positionStream.listen((position) {
        if (mounted && !_isDragging) {
          setState(() => _currentPosition = position);
        }
      }),
    );

    // Длительность
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() => _totalDuration = duration);
        }
      }),
    );

    // FIX: используем processingStateStream отдельно от playingStream,
    // чтобы не было гонки стейтов при завершении трека.
    _subscriptions.add(
      _player.playingStream.listen((playing) {
        if (!mounted) return;
        // Не трогаем _isPlaying здесь если трек завершён — это обработает processingStateStream
        if (_player.processingState != ProcessingState.completed) {
          setState(() => _isPlaying = playing);
        }
      }),
    );

    _subscriptions.add(
      _player.processingStateStream.listen((processingState) async {
        if (!mounted) return;
        if (processingState == ProcessingState.completed) {
          // FIX: сначала seek, потом обновляем UI — нет конфликта со стримом playing
          await _player.seek(Duration.zero);
          await _player.pause(); // явно паузируем, иначе playing=true остаётся
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentPosition = Duration.zero;
              _dragProgress = 0.0;
            });
          }
        }
      }),
    );

    await _loadAudio();
  }

  Future<void> _loadAudio() async {
    setState(() => _isLoading = true);
    try {
      await _player.setFilePath(widget.filePath);
    } catch (e) {
      debugPrint('Error loading audio: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_isLoading) return;

    if (_isPlaying) {
      await _player.pause();
      widget.onStop?.call();
    } else {
      // FIX: проверяем processingState, а не сравниваем Duration — надёжнее
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
      widget.onPlay?.call();
    }
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragProgress = _getProgress();
    });
  }

  void _onDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_totalDuration.inMilliseconds == 0) return;

    // FIX: используем constraints.maxWidth — это реальная ширина виджета,
    // а не screenWidth - 100, которая была неточной
    final width = constraints.maxWidth.clamp(1.0, double.infinity);
    final progress = (details.localPosition.dx / width).clamp(0.0, 1.0);

    setState(() => _dragProgress = progress);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_totalDuration.inMilliseconds > 0) {
      final newPosition = Duration(
        milliseconds: (_totalDuration.inMilliseconds * _dragProgress).round(),
      );
      final wasPlaying = _isPlaying;
      await _player.seek(newPosition);
      if (wasPlaying) await _player.play();
    }
    setState(() => _isDragging = false);
  }

  void _onTapDown(TapDownDetails details, BoxConstraints constraints) {
    if (_totalDuration.inMilliseconds == 0) return;

    final width = constraints.maxWidth.clamp(1.0, double.infinity);
    final progress = (details.localPosition.dx / width).clamp(0.0, 1.0);
    final newPosition = Duration(
      milliseconds: (_totalDuration.inMilliseconds * progress).round(),
    );

    final wasPlaying = _isPlaying;
    _player.seek(newPosition);
    if (wasPlaying) _player.play();
  }

  void _handleDelete() {
    _player.stop();
    widget.onDelete?.call();
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds == 0) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  double _getProgress() {
    if (_isDragging) return _dragProgress;
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _getProgress();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF555555),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _togglePlayback,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.accentColor,
                      width: 2,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: widget.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: const TextStyle(
                        fontFamily: 'DotGothic',
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDuration(_totalDuration),
                      style: const TextStyle(
                        fontFamily: 'DotGothic',
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.onDelete != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleDelete,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          if (_totalDuration.inMilliseconds > 0)
            LayoutBuilder(
              builder: (context, constraints) {
                // FIX: теперь barWidth берём из constraints, а не из MediaQuery
                final barWidth = constraints.maxWidth - 20; // 20 = иконка + отступ
                return Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (details) => _onTapDown(details, constraints),
                        onHorizontalDragStart: _onDragStart,
                        onHorizontalDragUpdate: (details) =>
                            _onDragUpdate(details, constraints),
                        onHorizontalDragEnd: _onDragEnd,
                        child: Container(
                          height: 30,
                          alignment: Alignment.center,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Трек (фон)
                              Container(
                                height: 4,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              // Заполненная часть
                              Container(
                                height: 4,
                                width: barWidth * progress,
                                decoration: BoxDecoration(
                                  color: widget.accentColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              // Ползунок
                              Positioned(
                                left: (barWidth * progress) - 6,
                                top: -4,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: widget.accentColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
