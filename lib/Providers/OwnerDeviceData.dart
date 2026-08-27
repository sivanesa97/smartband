import 'package:flutter/material.dart';

class OwnerDeviceData with ChangeNotifier {
  int _spo2 = 0;
  int _heartRate = 0;
  int _age = 0;
  bool _sosClicked = false;
  int _systolicBp = 0;
  int _diastolicBp = 0;
  double _bodyTemp = 0.0;
  int _stepCount = 0;
  int _sleepWakefulness = 0;
  int _sleepLight = 0;
  int _sleepDeep = 0;

  int get spo2 => _spo2;
  int get heartRate => _heartRate;
  int get age => _age;
  bool get sosClicked => _sosClicked;
  int get systolicBp => _systolicBp;
  int get diastolicBp => _diastolicBp;
  double get bodyTemp => _bodyTemp;
  int get stepCount => _stepCount;
  int get sleepWakefulness => _sleepWakefulness;
  int get sleepLight => _sleepLight;
  int get sleepDeep => _sleepDeep;

  void updateStatus({
    required int heartRate,
    required int spo2,
    required int age,
    required bool sosClicked,
    int systolicBp = 0,
    int diastolicBp = 0,
    double bodyTemp = 0.0,
    int stepCount = 0,
    int sleepWakefulness = 0,
    int sleepLight = 0,
    int sleepDeep = 0,
  }) {
    _heartRate = heartRate;
    _spo2 = spo2;
    _age = age;
    _sosClicked = sosClicked;
    _systolicBp = systolicBp;
    _diastolicBp = diastolicBp;
    _bodyTemp = bodyTemp;
    _stepCount = stepCount;
    _sleepWakefulness = sleepWakefulness;
    _sleepLight = sleepLight;
    _sleepDeep = sleepDeep;
    notifyListeners();
  }
}

