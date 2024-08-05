import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartband/Screens/Dashboard/connected.dart';

import 'Screens/Dashboard/dashboard.dart';
import 'Screens/InstructionsScreen/instructions.dart';

class BluetoothDeviceManager {
  static final BluetoothDeviceManager _instance = BluetoothDeviceManager._internal();

  factory BluetoothDeviceManager() {
    return _instance;
  }

  BluetoothDeviceManager._internal() {
    _initialize();
  }

  List<ScanResult> scanResults = [];
  bool isComplete = false;
  List<BluetoothDevice> connectedDevices = [];
  List<BluetoothService> services = [];
  Map<String, String> characteristicValues = {};

  final StreamController<List<BluetoothDevice>> connectedDevicesController =
  StreamController<List<BluetoothDevice>>.broadcast();

  // Public getter for connectedDevicesStream
  Stream<List<BluetoothDevice>> get connectedDevicesStream => connectedDevicesController.stream;

  final StreamController<Map<String, String>> characteristicValuesController =
  StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get characteristicValuesStream => characteristicValuesController.stream;

  void _initialize() {
    FlutterBluePlus.adapterState.listen((state) async {
      if (state != BluetoothAdapterState.on) {
        scanResults.clear();
        connectedDevicesController.add(connectedDevices);
        print("Bluetooth is off");
      }
    }, onError: (error) {
      print("Bluetooth state error: $error");
    });
  }

  Future<void> getPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (statuses[Permission.bluetooth] != PermissionStatus.granted ||
        statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.bluetoothConnect] != PermissionStatus.granted ||
        statuses[Permission.locationWhenInUse] != PermissionStatus.granted) {
      print("Some permissions are not granted");
    }
  }

  void scanForDevices(BuildContext context) async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    print("Scan started");

    FlutterBluePlus.scanResults.listen((results) async {
      scanResults = [];
      for (var result in results) {
        print('Device found: ${result.device.platformName} (${result.device.remoteId})');
        if (result.device.platformName.isNotEmpty) {
          scanResults.add(result);
          // if (result.device.platformName.startsWith("Noise"))
          //   {
          //     try {
          //       connectToDevice(result.device, context, true);
          //     }
          //     catch (Exception){
          //       print(Exception);
          //     }
          //   }
        }
      }
    });
    connectedDevices = FlutterBluePlus.connectedDevices;
    connectedDevicesController.add(connectedDevices);
    print("Connected devices : ${connectedDevices}");

    Future.delayed(const Duration(seconds: 15), () {
      FlutterBluePlus.stopScan();
      print("Scan stopped");
    });
  }

  Future<void> connectToDevice(BluetoothDevice device, BuildContext context, bool hasDeviceId) async {
    try {
      final data = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      String deviceName = data.data()?['device_id'] ?? '';

      if (deviceName.isEmpty || deviceName == device.platformName) {
        await device.connect();
        // Navigator.of(context).push(
        //   MaterialPageRoute(builder: (context) => DashboardScreen(device_name: device.platformName, mac_address: device.remoteId.toString(), device: device))
        // );
        connectedDevices.add(device);
        connectedDevicesController.add(connectedDevices); // Update connected devices list

        final bsSubscription = device.bondState.listen((value) {
          print("Bond State: $value");
        });
        device.cancelWhenDisconnected(bsSubscription);
        await device.createBond();

        device.connectionState.listen((state) async {
          if (state == BluetoothConnectionState.disconnected) {
            print("Not connected to device: ${device.platformName}");
            connectedDevices.remove(device);
            connectedDevicesController.add(connectedDevices);
          } else {
            print("Connected to device: ${device.platformName}");
            if (deviceName.isEmpty) {
              await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
                "device_id": device.platformName
              });
            }
            isComplete = true;
            connectedDevicesController.add(connectedDevices);
          }
        });
        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => Connected()));
      } else {
        print("Device ID doesn't match");
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Device ID are not matching. Please check'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }


  Future<void> discoverServicesAndCharacteristics(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.read) {
            // Periodically read the characteristic value
            Timer.periodic(Duration(seconds: 3), (timer) async {
              try {
                List<int> value = await characteristic.read();
                String decodedValue = utf8.decode(value).toString();
                characteristicValues[characteristic.uuid.toString()] = decodedValue;
                characteristicValuesController.add(characteristicValues);
              } catch (e) {
                print('Error reading characteristic: $e');
                timer.cancel(); // Stop the timer if there's an error
              }
            });
          }

          if (characteristic.properties.notify) {
            try {
              await characteristic.setNotifyValue(true);
              characteristic.lastValueStream.listen((value) {
                String decodedValue = utf8.decode(value).toString();
                characteristicValues[characteristic.uuid.toString()] = decodedValue;
                characteristicValuesController.add(characteristicValues);
              });
            } catch (e) {
              print('Error setting notification: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error discovering services and characteristics: $e');
    }
  }


  void disconnectFromDevice() async {
    if (connectedDevices.isNotEmpty) {
      try {
        print("Disconnecting from device: ${connectedDevices.first}");
        await connectedDevices.first.removeBond();
        await connectedDevices.first.disconnect();
        connectedDevices.removeAt(0);
        connectedDevicesController.add(connectedDevices); // Update the list after disconnection
        print("Disconnected from device");
      } catch (e) {
        print('Error disconnecting from device: $e');
      }
    } else {
      print("No device to disconnect from");
    }
  }
  void dispose() {
    connectedDevicesController.close();
    characteristicValuesController.close();
  }
}
