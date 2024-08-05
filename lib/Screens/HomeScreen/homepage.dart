import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/bluetooth.dart';
import 'package:smartband/pushnotifications.dart';

import '../Dashboard/dashboard.dart';
import '../Dashboard/notConnected.dart';

class HomepageScreen extends StatefulWidget {
  final bool hasDeviceId;

  HomepageScreen({Key? key, required this.hasDeviceId}) : super(key: key);

  @override
  _HomepageScreenState createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  String role1 = "watch wearer";
  String phNo = "";
  final BluetoothDeviceManager bluetoothDeviceManager = BluetoothDeviceManager();

  Future<void> _initializeBluetooth() async {
    print(widget.hasDeviceId);
    FlutterBluePlus.adapterState.listen((state) async {
      if (state == BluetoothAdapterState.on) {
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

  Future<Position> updateLocation() async {
    Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print("Fetched Location");

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .update({"location": GeoPoint(location.latitude, location.longitude)});

    final data = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid).get();
    final curr_location = data.data()!['home_location'] as GeoPoint;
    final role = data.data()?['role'];
    final phone = data.data()?['phone_number'];
    setState(() {
      role1 = role;
      phNo = phone.toString();
    });
    final distance = Geolocator.distanceBetween(location.latitude, location.longitude, curr_location.latitude, curr_location.longitude);
    print(distance%1000);
    if (distance%1000 > 10)
      {
        final data = await FirebaseFirestore.instance.collection("users").where('relations', arrayContains: FirebaseAuth.instance.currentUser!.email).get();
        SendNotification send = SendNotification();
        print("Sending");
        for(QueryDocumentSnapshot<Map<String, dynamic>> i in data.docs)
        {
          await Future.delayed(Duration(seconds: 5), (){});
          print("Email : ${i.data()['email']}");
          // send.sendNotification(i.data()['email'], "Emergency!!", "User has moved out to ${curr_location.latitude}°N ${curr_location.longitude}°E. Please check");
          print("Message sent");
        }

      }

    return location;
  }

  @override
  void initState() {
    super.initState();
    updateLocation();
    _initializeBluetooth();
  }

  @override
  Widget build(BuildContext context) {
    return role1 == 'supervisor'
        ? SupervisorDashboard(phNo: phNo,)
        : StreamBuilder<List<BluetoothDevice>>(
      stream: bluetoothDeviceManager.connectedDevicesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print(snapshot.data);
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
          return NotConnectedPage(
            hasDeviceId: widget.hasDeviceId,
          );
        }
      },
    );
  }
}