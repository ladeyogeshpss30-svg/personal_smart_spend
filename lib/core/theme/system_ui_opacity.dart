import 'package:flutter/material.dart';

class SystemUiOpacity {
  /// Returns safe opacity near system UI
  /// 0.10 → normal glass effect
  /// 0.15 → stronger contrast near system UI
  static double resolve({
    required BuildContext context,
    required bool nearSystemUi,
  }) {
    return nearSystemUi ? 0.15 : 0.10;
  }
}
