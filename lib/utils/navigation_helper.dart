import 'package:flutter/material.dart';

class NavigationHelper {
  /// 화면 이동 (push)
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget screen, {
    String? routeName,
  }) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute<T>(
        builder: (context) => screen,
        settings: RouteSettings(name: routeName),
      ),
    );
  }
  
  /// 화면 이동 (pushReplacement)
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget screen, {
    String? routeName,
  }) {
    return Navigator.pushReplacement<T, TO>(
      context,
      MaterialPageRoute<T>(
        builder: (context) => screen,
        settings: RouteSettings(name: routeName),
      ),
    );
  }
  
  /// 화면 이동 (pushAndRemoveUntil)
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Widget screen, {
    String? routeName,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.pushAndRemoveUntil<T>(
      context,
      MaterialPageRoute<T>(
        builder: (context) => screen,
        settings: RouteSettings(name: routeName),
      ),
      predicate ?? (route) => false,
    );
  }
  
  /// 이전 화면으로 돌아가기
  static void pop<T extends Object?>(
    BuildContext context, [
    T? result,
  ]) {
    Navigator.pop<T>(context, result);
  }
  
  /// 특정 라우트로 이동
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }
  
  /// 라우트 이름으로 교체
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      arguments: arguments,
      result: result,
    );
  }
  
  /// 라우트 이름으로 이동하고 스택 정리
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }
  
  /// 홈으로 이동 (스택 정리)
  static Future<T?> pushToHome<T extends Object?>(
    BuildContext context,
    Widget homeScreen,
  ) {
    return pushAndRemoveUntil<T>(
      context,
      homeScreen,
      predicate: (route) => false,
    );
  }
  
  /// 로그인 화면으로 이동 (스택 정리)
  static Future<T?> pushToLogin<T extends Object?>(
    BuildContext context,
    Widget loginScreen,
  ) {
    return pushAndRemoveUntil<T>(
      context,
      loginScreen,
      predicate: (route) => false,
    );
  }
  
  /// 다이얼로그 표시
  static Future<T?> showDialog<T extends Object?>(
    BuildContext context,
    Widget dialog,
  ) {
    return showGeneralDialog<T>(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => dialog,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }
  
  /// 스낵바 표시
  static void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }
}
