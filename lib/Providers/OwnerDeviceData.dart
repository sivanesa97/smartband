import 'package:flutter/material.dart';

class OwnerDeviceData with ChangeNotifier {
  int _spo2 = 0;
  int _heartRate = 0;
  int _age = 0;

  int get spo2 => _spo2;
  int get heartRate => _heartRate;
  int get age => _age;

  void updateStatus({required int heartRate, required int spo2, required int age}) {
    _heartRate = heartRate;
    _spo2 = spo2;
    _age = age;
    notifyListeners();
  }
}
