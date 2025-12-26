import 'package:flutter/material.dart';

class SafePadding {
  static EdgeInsets scroll(BuildContext context,
      {double extra = 16}) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return EdgeInsets.fromLTRB(16, 16, 16, bottom + extra);
  }
}
