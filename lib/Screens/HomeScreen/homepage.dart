import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/bluetooth.dart';

import '../Dashboard/dashboard.dart';
import '../Dashboard/notConnected.dart';

class HomepageScreen extends StatefulWidget {
  bool hasDeviceId;

  HomepageScreen({Key? key, required this.hasDeviceId}) : super(key: key);

  @override
  _HomepageScreenState createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  String role1 = "";
  final BluetoothDeviceManager bluetoothDeviceManager =
      BluetoothDeviceManager();

  void _initializeBluetooth() {
    print(widget.hasDeviceId);
    FlutterBluePlus.adapterState.listen((state) async {
      if (state == BluetoothAdapterState.on) {
        await getPermissions();

        // Retrieve the list of connected devices
        List<BluetoothDevice> devices = await FlutterBluePlus.connectedDevices;
        bluetoothDeviceManager.connectedDevicesController.add(devices);

        // Listen for changes in connected devices
        bluetoothDeviceManager.connectedDevicesController
            .add(FlutterBluePlus.connectedDevices);
      } else {
        bluetoothDeviceManager.connectedDevicesController.add([]);
      }
    });
  }

  Future<void> getPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.notification
    ].request();
  }

  Future<Position> updateLocation() async {
    Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print("Fetched Location");

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .update({"location": GeoPoint(location.latitude, location.longitude)});
    return location;
  }

  Future<String?> getRole() async {
    final role = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    setState(() {
      role1 = role.data()?['role'] ?? "";
    });
    return null;
  }

  @override
  void initState() {
    super.initState();
    updateLocation();
    getRole();
    getPermissions().then((_) async {
      _initializeBluetooth();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(role1);
    return role1 == 'supervisor'
        ? SupervisorDashboard()
        : StreamBuilder<List<BluetoothDevice>>(
            stream: bluetoothDeviceManager.connectedDevicesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data!.isNotEmpty) {
                // Navigate to DashboardScreen if devices are connected
                String deviceName = snapshot.data!.first.platformName;
                bluetoothDeviceManager
                    .discoverServicesAndCharacteristics(snapshot.data!.first);
                return DashboardScreen(
                  device: snapshot.data!.first,
                  device_name: deviceName,
                  mac_address: snapshot.data!.first.remoteId.toString(),
                );
              } else {
                // Show NotConnectedPage if no devices are connected or Bluetooth is off
                return NotConnectedPage(
                  hasDeviceId: false,
                );
              }
            },
          );
  }
}
