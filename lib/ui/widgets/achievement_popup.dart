import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/models/achievement.dart';

const _svgBase = 'lib/ui/assets/pixelariticons_svg/';

class AchievementUnlockDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockDialog({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF18221C),
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ДОСТИЖЕНИЕ',
              style: TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 11,
                color: Colors.white38,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _AchievementSvgIcon(achievement: achievement, size: 80),
            const SizedBox(height: 20),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 20,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    color: Colors.amber.withOpacity(0.08),
                  ),
                  child: const Text(
                    'Отлично!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 14,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementSvgIcon extends StatelessWidget {
  final Achievement achievement;
  final double size;

  const _AchievementSvgIcon({required this.achievement, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final svgPath = achievement.isAchieved
        ? '$_svgBase${achievement.iconAsset}'
        : '${_svgBase}question_mark.svg';

    return SvgPicture.asset(
      svgPath,
      width: size,
      height: size,
      colorFilter: achievement.isAchieved
          ? null
          : const ColorFilter.mode(Colors.white24, BlendMode.srcIn),
    );
  }
}

Widget achievementIcon(Achievement a) =>
    _AchievementSvgIcon(achievement: a, size: 64);
