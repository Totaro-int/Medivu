import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? fontSize;
  final FontWeight? fontWeight;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final IconData? icon;
  final bool showShadow;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
    this.padding,
    this.icon,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = isEnabled && !isLoading && onPressed != null;
    
    return Container(
      width: width,
      height: height ?? 56,
      decoration: showShadow
          ? BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusMedium),
              boxShadow: isButtonEnabled
                  ? [
                      BoxShadow(
                        color: (backgroundColor ?? Color(AppConstants.primaryColor)).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            )
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isButtonEnabled ? onPressed : null,
          borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Container(
            decoration: BoxDecoration(
              color: isButtonEnabled
                  ? (backgroundColor ?? Color(AppConstants.primaryColor))
                  : Colors.grey.withValues(alpha: 0.3),
              borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Center(
              child: Padding(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            textColor ?? Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              color: textColor ?? Colors.white,
                              size: (fontSize ?? AppConstants.bodyFontSize) + 2,
                            ),
                            const SizedBox(width: AppConstants.paddingSmall),
                          ],
                          Text(
                            text,
                            style: TextStyle(
                              color: textColor ?? Colors.white,
                              fontSize: fontSize ?? AppConstants.bodyFontSize,
                              fontWeight: fontWeight ?? FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? borderColor;
  final Color? textColor;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final double? fontSize;
  final FontWeight? fontWeight;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.borderColor,
    this.textColor,
    this.backgroundColor,
    this.width,
    this.height,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
    this.padding,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = isEnabled && !isLoading && onPressed != null;
    
    return SizedBox(
      width: width,
      height: height ?? 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isButtonEnabled ? onPressed : null,
          borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.transparent,
              border: Border.all(
                color: isButtonEnabled
                    ? (borderColor ?? Color(AppConstants.primaryColor))
                    : Colors.grey.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Center(
              child: Padding(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            textColor ?? Color(AppConstants.primaryColor),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              color: textColor ?? Color(AppConstants.primaryColor),
                              size: (fontSize ?? AppConstants.bodyFontSize) + 2,
                            ),
                            const SizedBox(width: AppConstants.paddingSmall),
                          ],
                          Text(
                            text,
                            style: TextStyle(
                              color: isButtonEnabled
                                  ? (textColor ?? Color(AppConstants.primaryColor))
                                  : Colors.grey,
                              fontSize: fontSize ?? AppConstants.bodyFontSize,
                              fontWeight: fontWeight ?? FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets? padding;
  final IconData? icon;
  final TextDecoration? decoration;

  const CustomTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.icon,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = isEnabled && !isLoading && onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isButtonEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppConstants.paddingSmall),
          child: isLoading
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Color(AppConstants.primaryColor),
              ),
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isButtonEnabled
                      ? (textColor ?? Color(AppConstants.primaryColor))
                      : Colors.grey,
                  size: (fontSize ?? AppConstants.bodyFontSize) + 2,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
              ],
              Text(
                text,
                style: TextStyle(
                  color: isButtonEnabled
                      ? (textColor ?? Color(AppConstants.primaryColor))
                      : Colors.grey,
                  fontSize: fontSize ?? AppConstants.bodyFontSize,
                  fontWeight: fontWeight ?? FontWeight.w500,
                  decoration: decoration,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double? iconSize;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.iconSize,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = isEnabled && !isLoading && onPressed != null;
    final buttonSize = size ?? 48;
    
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: borderRadius ?? BorderRadius.circular(buttonSize / 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isButtonEnabled ? onPressed : null,
          borderRadius: borderRadius ?? BorderRadius.circular(buttonSize / 2),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        iconColor ?? Color(AppConstants.primaryColor),
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: isButtonEnabled
                        ? (iconColor ?? Color(AppConstants.primaryColor))
                        : Colors.grey,
                    size: iconSize ?? (buttonSize * 0.5),
                  ),
          ),
        ),
      ),
    );
  }
}
