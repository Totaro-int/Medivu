import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ActFinderLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final bool showText;
  final double textSize;
  final FontWeight fontWeight;

  const ActFinderLogo({
    super.key,
    this.width,
    this.height,
    this.color,
    this.showText = true,
    this.textSize = 24.0,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 로고 아이콘 (임시로 Icon 위젯 사용)
        Container(
          width: width ?? 40,
          height: height ?? 40,
          decoration: BoxDecoration(
            color: color ?? Color(AppConstants.primaryColor),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: (width ?? 40) * 0.6,
          ),
        ),
        
        if (showText) ...[
          const SizedBox(width: AppConstants.paddingSmall),
          Text(
            'ActFinder',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: fontWeight,
              color: color ?? Color(AppConstants.primaryColor),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class ActFinderLogoVertical extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final bool showText;
  final double textSize;
  final FontWeight fontWeight;
  final double spacing;

  const ActFinderLogoVertical({
    super.key,
    this.width,
    this.height,
    this.color,
    this.showText = true,
    this.textSize = 24.0,
    this.fontWeight = FontWeight.bold,
    this.spacing = AppConstants.paddingSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 로고 아이콘
        Container(
          width: width ?? 80,
          height: height ?? 80,
          decoration: BoxDecoration(
            color: color ?? Color(AppConstants.primaryColor),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: (color ?? Color(AppConstants.primaryColor)).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: (width ?? 80) * 0.5,
          ),
        ),
        
        if (showText) ...[
          SizedBox(height: spacing),
          Text(
            'ActFinder',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: fontWeight,
              color: color ?? Color(AppConstants.primaryColor),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '행동을 찾아내는 앱',
            style: TextStyle(
              fontSize: textSize * 0.4,
              fontWeight: FontWeight.normal,
              color: color?.withValues(alpha: 0.7) ?? Color(AppConstants.primaryColor).withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class ActFinderLogoAnimated extends StatefulWidget {
  final double? width;
  final double? height;
  final Color? color;
  final bool showText;
  final double textSize;
  final FontWeight fontWeight;
  final Duration animationDuration;

  const ActFinderLogoAnimated({
    super.key,
    this.width,
    this.height,
    this.color,
    this.showText = true,
    this.textSize = 24.0,
    this.fontWeight = FontWeight.bold,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<ActFinderLogoAnimated> createState() => _ActFinderLogoAnimatedState();
}

class _ActFinderLogoAnimatedState extends State<ActFinderLogoAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: ActFinderLogo(
              width: widget.width,
              height: widget.height,
              color: widget.color,
              showText: widget.showText,
              textSize: widget.textSize,
              fontWeight: widget.fontWeight,
            ),
          ),
        );
      },
    );
  }
}
