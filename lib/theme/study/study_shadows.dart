import 'package:flutter/material.dart';

class StudyShadows {
  StudyShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 28, offset: Offset(0, 12)),
  ];
}
