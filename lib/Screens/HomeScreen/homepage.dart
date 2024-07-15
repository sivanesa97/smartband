import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Dashboard/dashboard.dart';
import '../Dashboard/notConnected.dart';

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
    flutterBlue.state.listen((state) async {
      if (state == BluetoothState.on) {
        // Ensure permissions are granted before fetching connected devices
        await getPermissions();

        // Retrieve the list of connected devices
        List<BluetoothDevice> devices = await flutterBlue.connectedDevices;
        _connectedDevicesController.add(devices);

        // Listen for changes in connected devices
        flutterBlue.connectedDevices.asStream().listen((List<BluetoothDevice> devices) {
          _connectedDevicesController.add(devices);
        });
      } else {
        _connectedDevicesController.add([]);
      }
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
  void initState() {
    super.initState();
    getPermissions().then((_) {
      _initializeBluetooth();
    });
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
        } else if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          // Navigate to DashboardScreen if devices are connected
          print("Devices: ${snapshot.data}");
          String deviceName = snapshot.data!.first.name;
          return DashboardScreen(device_name: deviceName, mac_address: snapshot.data!.first.id.toString(),);
        } else {
          // Show NotConnectedPage if no devices are connected or Bluetooth is off
          return NotConnectedPage();
        }
      },
    );
  }
}