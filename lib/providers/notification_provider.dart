import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {
  final List<Map<String, String>> _notifications = [];

  List<Map<String, String>> get notifications => _notifications;

  void addNotification(String title, String body) {
    _notifications.add({'title': title, 'body': body});
    notifyListeners();
  }

  void removeNotification(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications.removeAt(index);
      notifyListeners();
    }
  }
}