import 'package:flutter/material.dart';

class SubscriptionDataProvider with ChangeNotifier {
  bool _isActive = false;
  bool _isSubscribed = false;
  String _deviceId = "";

  bool get isActive => _isActive;
  bool get isSubscribed => _isSubscribed;
  String get deviceId => _deviceId;

  void updateStatus({required bool active, required bool subscribed, required String deviceName}) {
    _isActive = active;
    _isSubscribed = subscribed;
    _deviceId = deviceName;
    notifyListeners();
  }
}
