import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SvgIcons {
  static const String addBoxMultiple = 'assets/icons/add-box-multiple.svg';
  static const String analytics = 'assets/icons/analytics.svg';
  static const String arrowLeft = 'assets/icons/arrow-left.svg';
  static const String arrowRight = 'assets/icons/arrow-right.svg';
  static const String camera = 'assets/icons/camera.svg';
  static const String circle = 'assets/icons/circle.svg';
  static const String clock = 'assets/icons/clock.svg';
  static const String cloudSun = 'assets/icons/cloud-sun.svg';
  static const String editBox = 'assets/icons/edit-box.svg';
  static const String heart = 'assets/icons/heart.svg';
  static const String moonStars = 'assets/icons/moon-stars.svg';
  static const String search = 'assets/icons/search.svg';
  static const String upload = 'assets/icons/upload.svg';
  static const String user = 'assets/icons/user.svg';
  static const String wallet = 'assets/icons/wallet.svg';
}

class SvgIcon extends StatelessWidget {
  final String assetName;
  final double size;
  final Color? color;
  final VoidCallback? onTap;

  const SvgIcon({
    super.key,
    required this.assetName,
    this.size = 24,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      assetName,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: icon,
      );
    }

    return icon;
  }
}