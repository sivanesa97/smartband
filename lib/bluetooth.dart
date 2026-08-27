import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:smartband/Providers/OwnerDeviceData.dart';
import 'package:smartband/Screens/Dashboard/connected.dart';
import 'package:http/http.dart' as http;
import 'package:smartband/Screens/Dashboard/dashboard.dart';
import 'package:smartband/Screens/DrawerScreens/emergencycard.dart';
import 'package:smartband/Screens/Models/usermodel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/pushnotifications.dart';
import 'package:intl/intl.dart';
import 'package:smartband/Constants/api_constants.dart';
import 'package:smartband/Screens/Models/watch_data_payload.dart';

class BluetoothDeviceManager {
  static const String watchDataServiceUuid = "6e40ff01-b5a3-f393-e0a9-e50e24dcca9e";
  static const String watchDataCharUuid = "6e40ff03-b5a3-f393-e0a9-e50e24dcca9e";
  static const String timeSyncServiceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String timeSyncRxCharUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  static const String timeSyncTxCharUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  static final BluetoothDeviceManager _instance =
      BluetoothDeviceManager._internal();

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
  bool _isEmergency = false;

  final StreamController<List<BluetoothDevice>> connectedDevicesController =
      StreamController<List<BluetoothDevice>>.broadcast();

  // Public getter for connectedDevicesStream
  Stream<List<BluetoothDevice>> get connectedDevicesStream =>
      connectedDevicesController.stream;

  final StreamController<Map<String, String>> characteristicValuesController =
      StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get characteristicValuesStream =>
      characteristicValuesController.stream;

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

  void scanForDevices(BuildContext context, bool hasDeviceId) async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));

    FlutterBluePlus.scanResults.listen((results) async {
      Set<ScanResult> uniqueResults = {};

      for (var result in results) {
        print(
            'device: ${result.device.platformName} (${result.device.remoteId})');
        if (result.device.platformName.isNotEmpty) {
          uniqueResults.add(result);

          if (hasDeviceId) {
            String deviceId = await getDeviceIdFromFirestore();
            if (deviceId.isNotEmpty &&
                (result.device.remoteId.str.toUpperCase() == deviceId.toUpperCase() ||
                 result.device.platformName.toLowerCase() == deviceId.toLowerCase())) {
              try {
                await connectToDevice(result.device, context, true);
              } catch (e) {
                print("error: $e");
              }
            }
          }
        }
      }

      // Set ஐ மீண்டும் பட்டியலாக மாற்றுகிறோம்
      scanResults = uniqueResults.toList();
    });

    connectedDevices = FlutterBluePlus.connectedDevices;
    connectedDevicesController.add(connectedDevices);

    Future.delayed(const Duration(seconds: 15), () {
      FlutterBluePlus.stopScan();
    });
  }

  Future<String> getDeviceIdFromFirestore() async {
    final data = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    return data.data()?['device_id'] ?? '';
  }

  Future<void> connectToDevice(
      BluetoothDevice device, BuildContext context, bool hasDeviceId) async {
    try {
      // final data = await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(FirebaseAuth.instance.currentUser!.uid)
      //     .get();
      // String deviceName = data.data()?['device_id'] ?? '';
      String deviceName = '';
      final data = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      var phoneNumber = data.data()?["phone_number"];
      if (phoneNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid Mobile Number!")));
        return;
      }
      final response = await http.post(
        Uri.parse(ApiConstants.checkMobileUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'mobile_number': '$phoneNumber',
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'].toString() == 'active' &&
            data['device_id'] != null &&
            data['device_id'].toString().isNotEmpty) {
          deviceName = data['device_id'].toString();
        }
      } else {
        print(response.statusCode);
      }

      if (deviceName.isEmpty ||
          device.remoteId.str.toUpperCase() == deviceName.toUpperCase() ||
          device.platformName.toLowerCase() == deviceName.toLowerCase()) {
        // if (true) {
        await device.connect();
        // Navigator.of(context).push(
        //   MaterialPageRoute(builder: (context) => DashboardScreen(device_name: device.platformName, mac_address: device.remoteId.toString(), device: device))
        // );

        connectedDevices.add(device);
        connectedDevicesController
            .add(connectedDevices); // Update connected devices list

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
            print("Connected to device: ${device.platformName} (${device.remoteId})");
            if (deviceName.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({"device_id": device.remoteId.str.isNotEmpty ? device.remoteId.str : device.platformName});
            }
            isComplete = true;
            connectedDevicesController.add(connectedDevices);
            await getDataFromDevice(device, context);
          }
        });
        if (!hasDeviceId) {
          Navigator.of(context, rootNavigator: true)
              .push(MaterialPageRoute(builder: (context) => Connected()));
        }
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

  Future<void> syncTimeToWatch(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == timeSyncServiceUuid) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                timeSyncRxCharUuid) {
              String timeStr =
                  "#time:${DateFormat('yyMMddHHmmss').format(DateTime.now())}";
              print("Sending Time Sync: $timeStr");
              await characteristic.write(
                utf8.encode(timeStr),
                withoutResponse:
                    characteristic.properties.writeWithoutResponse,
              );
            }
            if (characteristic.uuid.toString().toLowerCase() ==
                timeSyncTxCharUuid) {
              await characteristic.setNotifyValue(true);
              characteristic.lastValueStream.listen((val) {
                String resp = utf8.decode(val, allowMalformed: true);
                print("Time Sync Response: $resp");
              });
            }
          }
        }
      }
    } catch (e) {
      print("Error syncing time to watch: $e");
    }
  }

  Future<void> discoverServicesAndCharacteristics(
      BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.read) {
            // Periodically read the characteristic value
            Timer.periodic(Duration(seconds: 3), (timer) async {
              try {
                List<int> value = await characteristic.read();
                String decodedValue = utf8.decode(value, allowMalformed: true).toString();
                characteristicValues[characteristic.uuid.toString()] =
                    decodedValue;
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
                String uuidStr = characteristic.uuid.toString().toLowerCase();
                if (uuidStr == watchDataCharUuid && value.length >= 17) {
                  try {
                    WatchDataPayload payload =
                        WatchDataPayload.fromBytes(value);
                    characteristicValues[characteristic.uuid.toString()] =
                        jsonEncode(payload.toMap());
                  } catch (_) {
                    characteristicValues[characteristic.uuid.toString()] =
                        utf8.decode(value, allowMalformed: true);
                  }
                } else {
                  String decodedValue =
                      utf8.decode(value, allowMalformed: true).toString();
                  characteristicValues[characteristic.uuid.toString()] =
                      decodedValue;
                }
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

  Future<void> getDataFromDevice(
      BluetoothDevice device, BuildContext context) async {
    if (device.isConnected) {
      try {
        final ownerDeviceData =
            Provider.of<OwnerDeviceData>(context, listen: false);

        // Perform automatic time sync on connection
        await syncTimeToWatch(device);

        List<BluetoothService> services = await device.discoverServices();
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toLowerCase();
            if (charUuid == watchDataCharUuid ||
                charUuid == "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
              await characteristic.setNotifyValue(true);

              characteristic.lastValueStream.listen((value) {
                if (value.isEmpty) return;

                if (value.length >= 17 && charUuid == watchDataCharUuid) {
                  try {
                    WatchDataPayload payload =
                        WatchDataPayload.fromBytes(value);
                    print("Received SmartSync Watch Payload: $payload");

                    ownerDeviceData.updateStatus(
                      heartRate: payload.heartRate,
                      spo2: payload.spo2,
                      age: ownerDeviceData.age,
                      sosClicked: payload.sosStatus,
                      systolicBp: payload.systolicBp,
                      diastolicBp: payload.diastolicBp,
                      bodyTemp: payload.bodyTemp,
                      stepCount: payload.stepCount,
                      sleepWakefulness: payload.sleepWakefulness,
                      sleepLight: payload.sleepLight,
                      sleepDeep: payload.sleepDeep,
                    );

                    FirebaseFirestore.instance
                        .collection("users")
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .update({
                      "metrics": payload.toMap(),
                    });

                    if (payload.sosStatus && ownerDeviceData.sosClicked != true) {
                      _handleSOSClick(true, context);
                    }
                  } catch (e) {
                    print("Error parsing SmartSync Watch payload: $e");
                  }
                } else {
                  // Legacy CSV string parsing fallback
                  String decodedValue = String.fromCharCodes(value);
                  List<String> values = decodedValue.split(',');
                  print("Values: $values");
                  if (values.length >= 3) {
                    int newHeartRate = int.tryParse(values[0]) ?? 0;
                    int newSpO2 = int.tryParse(values[1]) ?? 0;

                    if (ownerDeviceData.heartRate != newHeartRate ||
                        ownerDeviceData.spo2 != newSpO2) {
                      ownerDeviceData.updateStatus(
                        heartRate: newHeartRate,
                        spo2: newSpO2,
                        age: ownerDeviceData.age,
                        sosClicked: false,
                      );

                      FirebaseFirestore.instance
                          .collection("users")
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .update({
                        "metrics": {
                          "spo2": newSpO2.toString(),
                          "heart_rate": newHeartRate.toString(),
                          "fall_axis": "--"
                        }
                      });
                    }
                  }
                }
              });
            }
          }
        }
      } catch (e) {
        print("Error getting data from device: $e");
      }
    } else {
      print("Device is not connected");
    }
  }

  Future<Position> updateLocation() async {
    Position location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print("Fetched Location");

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .update({"location": GeoPoint(location.latitude, location.longitude)});
    return location;
  }

  Future<void> _handleSOSClick(bool sosClicked, BuildContext context) async {
    final deviceOwnerData =
        Provider.of<OwnerDeviceData>(context, listen: false);
    _isEmergency = true;
    for (var attempt = 1; attempt <= 3; attempt++) {
      if (!_isEmergency) {
        break;
      }
      final now = DateTime.now();
      final currentDate = DateFormat('dd-MM-yyyy').format(now);
      final currentTime = DateFormat('hh:mm a').format(now);
      print("Attempt ");
      print(attempt);
      // Position location = await updateLocation();
      try {
        if (FirebaseAuth.instance.currentUser!.uid.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({
            "metrics": {
              "spo2": deviceOwnerData.spo2,
              "heart_rate": deviceOwnerData.heartRate,
              "fall_axis": "-- -- --"
            }
          });
        }
        final data = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();
        Position location = await updateLocation();
        SendNotification send = SendNotification();
        if (data.exists) {
          Map<String, dynamic> dataMap = data.data() as Map<String, dynamic>;
          print(dataMap);
          if (!_isEmergency) {
            break;
          }
          print("Sending");
          print(
              "Email : ${data.data()?['email']}"); // Fixed by adding null check
          print("Inside SOS Click");

          Map<String, Map<String, dynamic>> supervisors =
              Map<String, Map<String, dynamic>>.from(
                  data.data()?['supervisors']);
          var filteredSupervisors = supervisors.entries
              .where((entry) => entry.value['status'] == 'active')
              .toList()
            ..sort((a, b) => int.parse(b.value['priority'].toString())
                .compareTo(int.parse(a.value['priority'].toString())));

          for (var supervisor in filteredSupervisors) {
            if (!_isEmergency) {
              break;
            }
            final sup = await FirebaseFirestore.instance
                .collection("users")
                .where('phone_number', isEqualTo: supervisor.key)
                .get();
            await FirebaseFirestore.instance
                .collection("emergency_alerts")
                .doc(sup.docs.first.id)
                .set({
              "isEmergency": true,
              "responseStatus": false,
              "response": "",
              "phone_number": supervisor.key,
              "userUid": FirebaseAuth.instance.currentUser?.uid,
              "heartbeatRate": deviceOwnerData.heartRate,
              "location": "0°N 0°E",
              "spo2": deviceOwnerData.spo2,
              "fallDetection": false,
              "isManual": true,
              "date": currentDate,
              "time": currentTime,
              "timestamp": FieldValue.serverTimestamp()
            }, SetOptions(merge: true));

            await FirebaseFirestore.instance
                .collection("emergency_alerts")
                .doc(sup.docs.first.id)
                .collection(sup.docs.first.id)
                .add({
              "isEmergency": true,
              "responseStatus": false,
              "response": "",
              "heartbeatRate": deviceOwnerData.heartRate,
              "location": "0°N 0°E",
              "spo2": deviceOwnerData.spo2,
              "fallDetection": false,
              "isManual": true,
              "timestamp": FieldValue.serverTimestamp()
            });
            String responderName = data.data()?['name'] ?? "User";
            send.sendNotification(supervisor.key, "Emergency!!",
                "$responderName has clicked the SOS Button from ${location.latitude}°N ${location.longitude}°E. Please respond");

            print(
                "Message sent to supervisor with phone number: ${supervisor.key} and priority: ${supervisor.value}");

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Sent Alert to ${supervisor.key}")),
            );
            await Future.delayed(Duration(seconds: 30));
            FirebaseFirestore.instance
                .collection("emergency_alerts")
                .doc(sup.docs.first.id)
                .snapshots()
                .listen((DocumentSnapshot doc) {
              if (doc.exists && doc["responseStatus"] == true) {
                _isEmergency = false;
                FirebaseFirestore.instance
                    .collection("users")
                    .where('phone_number', isEqualTo: supervisor.key)
                    .get()
                    .then((QuerySnapshot snapshot) {
                  Map<String, dynamic> data =
                      snapshot.docs.first.data() as Map<String, dynamic>;
                  String responder = data['name'] ?? "User";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$responder Responded"),
                    ),
                  );
                });
              }
            });
          }
        }

        if (attempt == 3) {
          _isEmergency = false;
        }
      } catch (e) {
        print("Exception ${e}");
      }
    }
  }

  void disconnectFromDevice() async {
    if (connectedDevices.isNotEmpty) {
      try {
        print("Disconnecting from device: ${connectedDevices.first}");
        await connectedDevices.first.removeBond();
        await connectedDevices.first.disconnect();
        connectedDevices.removeAt(0);
        connectedDevicesController
            .add(connectedDevices); // Update the list after disconnection
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
