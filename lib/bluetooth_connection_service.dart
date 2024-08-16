import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;

class BluetoothConnectionService {
  static final BluetoothConnectionService _instance =
      BluetoothConnectionService._internal();
  factory BluetoothConnectionService() => _instance;
  BluetoothConnectionService._internal();

  BluetoothDevice? _connectedDevice;
  String? deviceId;

  Future<void> startBluetoothService() async {
    // Start scanning for devices
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final response = await http.post(
        Uri.parse("https://snvisualworks.com/public/api/auth/check-mobile"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'mobile_number': user.phoneNumber,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'].toString() != 'active') {
          deviceId = data['device_id'].toString();
        }
      } else {
        print(response.statusCode);
      }
    }
    FlutterBluePlus.scanResults.listen((results) {
      // Filter for your specific device
      for (ScanResult r in results) {
        if (r.device.platformName == deviceId) {
          _connectToDevice(r.device);
          break;
        }
      }
    });

    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await device.connect();
    _connectedDevice = device;
  }

  Future<void> checkAndReconnect() async {
    if (_connectedDevice == null ||
        _connectedDevice!.state != BluetoothDeviceState.connected) {
      await startBluetoothService();
    }
  }
}
