import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/Screens/Widgets/drawer.dart';
import 'package:smartband/Screens/Widgets/string_extensions.dart';
import 'package:smartband/bluetooth.dart';
import 'package:smartband/pushnotifications.dart';
import '../DrawerScreens/profilepage.dart';
import '../InstructionsScreen/instructions.dart';
import '../Widgets/appBar.dart';
import '../Widgets/appBarProfile.dart';
import 'dashboard.dart';

class NotConnectedPage extends StatefulWidget {
  bool hasDeviceId;

  NotConnectedPage({super.key, required this.hasDeviceId});

  @override
  State<NotConnectedPage> createState() => _NotConnectedPageState();
}

class _NotConnectedPageState extends State<NotConnectedPage> {
  List<BluetoothDevice> connectedDevices = [];
  List<ScanResult> listDevice = [];
  BluetoothDevice? selectedDevice;
  bool addDeviceBtn = false;
  String search_text = "Search for smartwatch";
  BluetoothDeviceManager bluetoothDeviceManager = BluetoothDeviceManager();

  @override
  void initState() {
    super.initState();
    addDeviceBtn = false;
    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      print(state);
    });
    if (Platform.isAndroid) {
      FlutterBluePlus.turnOn();
    }
    subscription.cancel();
    scanForDevices(context);
  }

  void connectToDevice(
      BluetoothDevice device, BuildContext context, bool hasDeviceId) async {
    try {
      await bluetoothDeviceManager.connectToDevice(
          device, context, widget.hasDeviceId);
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void scanForDevices(BuildContext context) {
    if (mounted) {
      try {
        bluetoothDeviceManager.scanForDevices(context);
        setState(() {
          search_text = "Scanning for devices";
        });
        Timer.periodic(Duration(milliseconds: 500), (Timer t) {
          setState(() {
            listDevice = bluetoothDeviceManager.scanResults;
          });
        });
        print("DEvices : ${bluetoothDeviceManager.scanResults}");
        print("Scan started");

        Future.delayed(const Duration(seconds: 15), () {
          if (mounted) {
            setState(() {
              search_text = "Search for smartwatch";
              listDevice = bluetoothDeviceManager.scanResults;
            });
          }
        });
      } catch (e) {
        print('Error scanning for devices: $e');
      }
    }
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerScreen(
        device: null,
        phNo: "",
      ),
      appBar: addDeviceBtn
          ? AppBar(
              surfaceTintColor: Colors.white,
              backgroundColor: Colors.white,
              leading: Padding(
                padding: const EdgeInsets.only(left: 0),
                child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      addDeviceBtn = false;
                    });
                  },
                  child: const Icon(Icons.chevron_left),
                ),
              ),
            )
          : AppBar(
              surfaceTintColor: Colors.white,
              backgroundColor: Colors.white,
              actions: [
                GestureDetector(
                  onTap: () async {
                    Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                            builder: (context) => const Profilepage()));
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: const Icon(
                      Icons.account_circle_outlined,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
      body: !addDeviceBtn
          ? Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 15.0, right: 15.0, top: 15.0),
                  child: Text(
                    "You have not linked a device",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: height * 0.035),
                  ),
                ),
                SizedBox(
                  height: height * 0.1,
                ),
                Padding(
                  padding: EdgeInsets.only(right: 15.0),
                  child: InkWell(
                    onTap: () async {
                      // Future<void> _handleSOSClick(bool sosClicked) async {
                      //   // Position location = await updateLocation();
                      //   try {
                      //     if (FirebaseAuth
                      //         .instance.currentUser!.uid.isNotEmpty) {
                      //       await FirebaseFirestore.instance
                      //           .collection("users")
                      //           .doc(FirebaseAuth.instance.currentUser!.uid)
                      //           .update({
                      //         "metrics": {
                      //           "spo2": "168",
                      //           "heart_rate": "200",
                      //           "fall_axis": "-- -- --"
                      //         }
                      //       });
                      //     }
                      //     final data = await FirebaseFirestore.instance
                      //         .collection("users")
                      //         .where('relations', arrayContains: "965538193")
                      //         .get();
                      //     SendNotification send = SendNotification();
                      //     for (QueryDocumentSnapshot<Map<String, dynamic>> i
                      //         in data.docs) {
                      //       print("Sending");
                      //       // await Future.delayed(Duration(seconds: 5), (){});
                      //       print("Email : ${i.data()['email']}");
                      //       await FirebaseFirestore.instance
                      //           .collection("emergency_alerts")
                      //           .doc(i.id)
                      //           .set({
                      //         "isEmergency": true,
                      //         "responseStatus": false,
                      //         "response": "",
                      //         "userUid": FirebaseAuth.instance.currentUser?.uid,
                      //         "heartbeatRate": 150,
                      //         "location": "",
                      //         "sfo2": 100,
                      //         "fallDetection": false,
                      //         "isManual": true
                      //       }, SetOptions(merge: true));

                      //       if (FirebaseAuth.instance.currentUser != null) {
                      //         await FirebaseFirestore.instance
                      //             .collection("emergency_alerts")
                      //             .doc(i.id)
                      //             .collection(
                      //                 FirebaseAuth.instance.currentUser?.uid ??
                      //                     "public")
                      //             .add({
                      //           "isEmergency": true,
                      //           "responseStatus": false,
                      //           "response": "",
                      //           "heartbeatRate": 150,
                      //           "location": "°N °E",
                      //           "sfo2": 100,
                      //           "fallDetection": false,
                      //           "isManual": true,
                      //           "timestamp": FieldValue.serverTimestamp()
                      //         });
                      //       }
                      //       // String? email = await FirebaseAuth.instance.currentUser!.email;
                      //       print("Sending to ");
                      //       print(i.data()['phone_number']);
                      //       try {
                      //         send.sendNotification(
                      //             i.data()['phone_number'].toString(),
                      //             "Emergency!!",
                      //             "SIVA has clicked SOS Button from °N °E. Please respond");
                      //         print("Message sent");
                      //         await Future.delayed(Duration(seconds: 30));
                      //       } catch (e) {
                      //         print(e);
                      //       }
                      //     }
                      //   } catch (e) {
                      //     print("Exception ${e}");
                      //   }

                      //   // Notify user
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     SnackBar(
                      //         content: Text("SOS alert sent to supervisors")),
                      //   );
                      // }

                      // await _handleSOSClick(true);
                      setState(() {
                        addDeviceBtn = true;
                        scanForDevices(context);
                      });
                    },
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: width * 0.5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 83, 188, 1),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset:
                                  Offset(0, 0), // changes position of shadow
                            ),
                          ],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "Add a Device",
                                style: TextStyle(
                                  color: Color.fromRGBO(0, 83, 188, 1),
                                ),
                              ),
                              Icon(
                                Icons.add,
                                color: Color.fromRGBO(0, 83, 188, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 25.0, vertical: 25.0),
                  child: Text(
                    "Add device",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: height * 0.03),
                  ),
                ),
                Center(
                  child: Text(
                    "Please select your smartwatch in the list",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: height * 0.025),
                  ),
                ),
                Center(
                  child: InkWell(
                    onTap: () {
                      scanForDevices(context);
                    },
                    child: Text(
                      search_text,
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: listDevice.length,
                    itemBuilder: (context, index) {
                      final device = listDevice[index];
                      if (device.device.platformName.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 10.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 83, 188, 1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: Offset(
                                      0, 0), // changes position of shadow
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 15.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: width * 0.5,
                                        child: Text(
                                          // "device${index+1}",
                                          device.device.platformName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: width * 0.5,
                                        child: Text(
                                          // "Mac address : ${index+1}",
                                          device.device.remoteId.toString(),
                                          style: const TextStyle(fontSize: 17),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: width * 0.3,
                                        child: TextButton(
                                            onPressed: () {
                                              connectToDevice(device.device,
                                                  context, widget.hasDeviceId);
                                              // Navigator.of(context).push(MaterialPageRoute(builder: (context) => DashboardScreen(device_name: "device_name", mac_address: "mac_address")));
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 10.0,
                                                  horizontal: 15.0),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  color: Colors.grey
                                                      .withOpacity(0.1)),
                                              child: const Text(
                                                "Connect",
                                                style: TextStyle(
                                                  color: Color.fromRGBO(
                                                      0, 83, 188, 1),
                                                ),
                                              ),
                                            )),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 15.0),
                                  child: Image.asset(
                                    "assets/watch.png",
                                    height: 100,
                                    width: 100,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
