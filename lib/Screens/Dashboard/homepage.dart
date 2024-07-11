import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dashboard.dart';
import 'notConnected.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({Key? key}) : super(key: key);

  @override
  _HomepageScreenState createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  final StreamController<List<BluetoothDevice>> _connectedDevicesController =
  StreamController<List<BluetoothDevice>>();

  void _initializeBluetooth() {
    flutterBlue.state.listen((state) {
      if (state == BluetoothState.on) {
        flutterBlue.connectedDevices.asStream().listen((List<BluetoothDevice> devices) {
          _connectedDevicesController.add(devices);
          // Optionally, you can print out the connected devices for debug purposes
          print("Devices: $devices");
        });
      } else {
        _connectedDevicesController.add([]);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getPermissions().then((_) {
      _initializeBluetooth();
    });
  }

  Future<void> getPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  @override
  void dispose() {
    _connectedDevicesController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BluetoothDevice>>(
      stream: _connectedDevicesController.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData) {
          if (snapshot.data!.isNotEmpty) {
            // Navigate to DashboardScreen if devices are connected
            return DashboardScreen();
          } else {
            // Show NotConnectedPage if no devices are connected
            return NotConnectedPage();
          }
        } else {
          // Show NotConnectedPage if no data or Bluetooth is off
          return NotConnectedPage();
        }
      },
    );
  }
}

