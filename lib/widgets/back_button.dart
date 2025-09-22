import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/navigation_helper.dart';

class BackButton extends StatelessWidget {
  final Color? color;
  final double? size;
  final VoidCallback? onPressed;
  final bool showText;
  final String? text;
  final IconData? icon;

  const BackButton({
    super.key,
    this.color,
    this.size,
    this.onPressed,
    this.showText = false,
    this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => NavigationHelper.pop(context),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.arrow_back_ios,
              color: color ?? Color(AppConstants.primaryColor),
              size: size ?? 20,
            ),
            if (showText) ...[
              const SizedBox(width: 4),
              Text(
                text ?? '뒤로',
                style: TextStyle(
                  color: color ?? Color(AppConstants.primaryColor),
                  fontSize: AppConstants.bodyFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BackButtonFloating extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final VoidCallback? onPressed;
  final IconData? icon;

  const BackButtonFloating({
    super.key,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + AppConstants.paddingMedium,
      left: AppConstants.paddingMedium,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed ?? () => NavigationHelper.pop(context),
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: size ?? 50,
              height: size ?? 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.arrow_back,
                color: iconColor ?? Color(AppConstants.primaryColor),
                size: (size ?? 50) * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BackButtonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBackPressed;

  const BackButtonAppBar({
    super.key,
    this.title,
    this.backgroundColor,
    this.foregroundColor,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                color: foregroundColor ?? Color(AppConstants.primaryColor),
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: automaticallyImplyLeading
          ? BackButton(
              onPressed: onBackPressed,
              color: foregroundColor ?? Color(AppConstants.primaryColor),
            )
          : null,
      actions: actions,
      iconTheme: IconThemeData(
        color: foregroundColor ?? Color(AppConstants.primaryColor),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class BackButtonWithTitle extends StatelessWidget {
  final String title;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback? onPressed;
  final bool showDivider;

  const BackButtonWithTitle({
    super.key,
    required this.title,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.onPressed,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingSmall,
          ),
          child: Row(
            children: [
              BackButton(
                onPressed: onPressed,
                color: iconColor,
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: AppConstants.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? Color(AppConstants.primaryColor),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 50), // BackButton과 대칭을 맞추기 위한 공간
            ],
          ),
        ),
      ),
    );
  }
}
