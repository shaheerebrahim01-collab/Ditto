import 'package:flutter/material.dart';

// Lets any screen (e.g. TailorProfileScreen's "Start customizing" button)
// switch MainShell's active bottom-nav tab, even when pushed on top of it.
class ShellNavigation extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void goTo(int index) {
    _index = index;
    notifyListeners();
  }
}
