import 'package:flutter/material.dart';

class SubscriptionDataProvider with ChangeNotifier {
  bool _isActive = false;
  bool _isSubscribed = false;
  String _deviceId = "";
  String _phoneNumber = "";

  bool get isActive => _isActive;
  bool get isSubscribed => _isSubscribed;
  String get deviceId => _deviceId;
  String get phoneNumber => _phoneNumber;

  void updateStatus({required bool active, required bool subscribed, required String deviceName, required String phoneNumber}) {
    _isActive = active;
    _isSubscribed = subscribed;
    _deviceId = deviceName;
    _phoneNumber = phoneNumber;
    notifyListeners();
  }
}
