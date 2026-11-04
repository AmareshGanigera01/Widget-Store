import 'package:flutter/material.dart';

const appSeedColor = Color(0xFF2E7D32);

ThemeData appTheme(Brightness brightness) =>
    ThemeData(colorSchemeSeed: appSeedColor, brightness: brightness, useMaterial3: true);
