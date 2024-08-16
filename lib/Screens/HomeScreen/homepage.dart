// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartband/Screens/AuthScreen/phone_number.dart';
import 'package:smartband/Screens/AuthScreen/signin.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/bluetooth.dart';
import 'package:smartband/pushnotifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;

import '../Dashboard/dashboard.dart';
import '../Dashboard/notConnected.dart';

class HomepageScreen extends StatefulWidget {
  final bool hasDeviceId;

  const HomepageScreen({super.key, required this.hasDeviceId});

  @override
  HomepageScreenState createState() => HomepageScreenState();
}

class HomepageScreenState extends State<HomepageScreen> {
  String role1 = "";
  String phNo = "";
  bool isSubscribed = false;
  String? deviceId;
  String status = '';
  String subscription = '';
  bool _isSubscriptionFetched = false;
  final BluetoothDeviceManager bluetoothDeviceManager =
      BluetoothDeviceManager();

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
        .doc(user.uid)
        .get();
    final curr_location = data.data()!['home_location'] as GeoPoint;
    final role = data.data()?['role'];
    final phone = data.data()?['phone_number'];
    print("role = $role");
    setState(() {
      role1 = role;
      phNo = phone.toString();
    });
    final distance = Geolocator.distanceBetween(location.latitude,
        location.longitude, curr_location.latitude, curr_location.longitude);
    print(distance % 1000);
    if (distance % 1000 > 10) {
      final data = await FirebaseFirestore.instance
          .collection("users")
          .where('relations',
              arrayContains: FirebaseAuth.instance.currentUser!.email)
          .get();
      SendNotification send = SendNotification();
      print("Sending");
      for (QueryDocumentSnapshot<Map<String, dynamic>> i in data.docs) {
        await Future.delayed(const Duration(seconds: 5), () {});
        print("Email : ${i.data()['email']}");
        // send.sendNotification(i.data()['email'], "Emergency!!", "User has moved out to ${curr_location.latitude}°N ${curr_location.longitude}°E. Please check");
        print("Message sent");
      }
    }

    return location;
  }

  Future<void> fetchSubscription(String phno) async {
    final response = await http.post(
      Uri.parse("https://snvisualworks.com/public/api/auth/check-mobile"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'mobile_number': phno,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      intl.DateFormat dateFormat = intl.DateFormat("dd-MM-yyyy");
      if (data['status'].toString() != 'active') {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("User not active")));
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => PhoneSignIn()),
            (Route<dynamic> route) => false);
        return;
      }

      DocumentReference docRef = FirebaseFirestore.instance
          .collection('server_time')
          .doc('current_time');
      await docRef.set({'timestamp': FieldValue.serverTimestamp()});

      DocumentSnapshot docSnapshot = await docRef.get();
      Timestamp serverTimestamp = docSnapshot['timestamp'];
      DateTime serverDate = serverTimestamp.toDate();
      if (data['subscription_date'] != null && data['end_date'] != null) {
        DateTime startDate =
            DateTime.parse(data['subscription_date'].toString());
        DateTime endDate = DateTime.parse(data['end_date'].toString());
        if ((startDate.isAtSameMomentAs(serverDate) ||
                startDate.isBefore(serverDate)) &&
            (endDate.isAtSameMomentAs(serverDate) ||
                endDate.isAfter(serverDate))) {
          setState(() {
            status = data['status'].toString();
            deviceId = data['device_id'].toString();
            subscription = data['subscription_period'] == null
                ? "--"
                : "${data['subscription_period'].toString()} Months";
            setState(() {
              _isSubscriptionFetched = true;
            });
            print("Fetched");
          });
        } else {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          await googleSignIn.signOut();
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Subscription To Continue")));
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => PhoneSignIn()),
              (Route<dynamic> route) => false);
          return;
        }
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subscribe to Continue!")));
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => PhoneSignIn()),
            (Route<dynamic> route) => false);
        return;
      }
    } else {
      print(response.statusCode);
    }
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
        ? SupervisorDashboard(
            phNo: phNo,
          )
        : StreamBuilder<List<BluetoothDevice>>(
            stream: bluetoothDeviceManager.connectedDevicesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print(snapshot.data);
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty) {
                // Navigate to DashboardScreen if devices are connected
                String? deviceName = snapshot.data!.first.platformName;
                bluetoothDeviceManager
                    .discoverServicesAndCharacteristics(snapshot.data!.first);
                if (deviceName == deviceId) {
                  deviceName = deviceId;
                } else {
                  deviceName = null;
                }
                return DashboardScreen(phNo,
                    device_name: deviceName,
                    subscription: subscription,
                    status: status,
                    mac_address: snapshot.data!.first.remoteId.toString(),
                    device: snapshot.data!.first);
              } else {
                return role1 == ""
                    ? const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : NotConnectedPage(
                        hasDeviceId: widget.hasDeviceId,
                      );
              }
            },
          );
  }
}
