import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart' as blue;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Screens/Dashboard/dashboard.dart';
import 'Screens/InstructionsScreen/instructions.dart';

class BluetoothDeviceManager {
  static final BluetoothDeviceManager _instance = BluetoothDeviceManager._internal();

  factory BluetoothDeviceManager() {
    return _instance;
  }

  BluetoothDeviceManager._internal();

  blue.FlutterBlue flutterBlue = blue.FlutterBlue.instance;
  List<blue.BluetoothDevice> connectedDevices = [];

  final StreamController<List<blue.BluetoothDevice>> _connectedDevicesController =
  StreamController<List<blue.BluetoothDevice>>();

  void initializeBluetooth() {
    flutterBlue.state.listen((state) async {
      if (state == blue.BluetoothState.on) {
        // Ensure permissions are granted before fetching connected devices
        await getPermissions();

        // Retrieve the list of connected devices
        List<blue.BluetoothDevice> devices =
        await flutterBlue.connectedDevices;
        connectedDevices.addAll(devices);
        _connectedDevicesController.add(connectedDevices);

        // Listen for changes in connected devices
        flutterBlue.connectedDevices.asStream().listen(
              (List<blue.BluetoothDevice> devices) {
            connectedDevices.clear();
            connectedDevices.addAll(devices);
            _connectedDevicesController.add(connectedDevices);
          },
        );
      } else {
        connectedDevices.clear();
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

  void scanForDevices(bool mounted) {
    if (mounted) {
      try {
        FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
        print("Scan started");

        FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
          // Update your UI with the scanned devices
          // Example:
          results.forEach((result) {
            print('Device found: ${result.device.name}');
          });
        });

        Future.delayed(const Duration(seconds: 15), () {
          FlutterBluePlus.stopScan();
          print("Scan stopped");
        });
      } catch (e) {
        print('Error scanning for devices: $e');
      }
    }
  }

  void connectToDevice(
      BluetoothDevice device, BuildContext context) async {
    try {
      await device.connect();

      final bsSubscription = device.bondState.listen((value) {
        print("Bond state: $value");
      });
      device.cancelWhenDisconnected(bsSubscription);
      await device.createBond();

      print("Connected to device: ${device.name}");

      // Add device to connectedDevices list
      connectedDevices.add(device as blue.BluetoothDevice);
      _connectedDevicesController.add(connectedDevices);

      // Navigate to another screen or update UI
      // Example:
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InstructionsScreen(
            onNext: () {
              print("Finished Instructions");
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(
                    device_name: device.name,
                    mac_address: device.id.toString(),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void disconnectFromDevice(blue.BluetoothDevice device) async {
    try {
      await device.disconnect();
      connectedDevices.remove(device);
      _connectedDevicesController.add(connectedDevices);
      print("Disconnected from device: ${device.name}");
    } catch (e) {
      print('Error disconnecting from device: $e');
    }
  }
}
