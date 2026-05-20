import 'package:flutter/material.dart';

class DynamicParamInput {
  final TextEditingController keyController;
  final TextEditingController valueController;

  DynamicParamInput()
    : keyController = TextEditingController(),
      valueController = TextEditingController();

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
