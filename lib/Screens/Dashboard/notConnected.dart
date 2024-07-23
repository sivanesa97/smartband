import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smartband/Screens/Widgets/drawer.dart';
import 'package:smartband/Screens/Widgets/string_extensions.dart';
import 'package:smartband/bluetooth.dart';
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
    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      print(state);
    });
    if (Platform.isAndroid) {
      FlutterBluePlus.turnOn();
    }
    subscription.cancel();
  }

  void connectToDevice(
      BluetoothDevice device, BuildContext context, bool hasDeviceId) async {
    try {
      await bluetoothDeviceManager.connectToDevice(device, context, widget.hasDeviceId);
      print(bluetoothDeviceManager.connectedDevices);
      if (hasDeviceId)
        {
          final data = await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({
            "device_id" : device.platformName
          });
        }
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void scanForDevices() {
    if (mounted) {
      try {
        bluetoothDeviceManager.scanForDevices();
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
    return Scaffold(
      backgroundColor: Colors.white,
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
              title: Align(
                alignment: const Alignment(-0.25, 0),
                child: Image.asset(
                  "assets/logo.jpg",
                  height: 60,
                ),
              ))
          : const AppBarProfileWidget(),
      drawer: const DrawerScreen(),
      body: !addDeviceBtn
          ? Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 15.0, right: 15.0, top: 15.0),
                  child: Text(
                    "You have not linked a device",
                    style: TextStyle(fontSize: 36),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        addDeviceBtn = true;
                        scanForDevices();
                      });
                    },
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: width * 0.5,
                        decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(10),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "Add a Device",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Icon(Icons.add, color: Colors.white,),
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
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 25.0, vertical: 25.0),
                  child: Text(
                    "Add device",
                    style: TextStyle(fontSize: 30),
                  ),
                ),
                const Center(
                  child: Text(
                    "Please select your smartwatch in the list",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17),
                  ),
                ),
                Center(
                  child: InkWell(
                    onTap: () {
                      scanForDevices();
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
                              horizontal: 15.0, vertical: 8.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: Colors.grey,
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
                                        child: ElevatedButton(
                                          onPressed: () {
                                            connectToDevice(device.device,
                                                context, widget.hasDeviceId);
                                            // Navigator.of(context).push(MaterialPageRoute(builder: (context) => DashboardScreen(device_name: "device_name", mac_address: "mac_address")));
                                          },
                                          child: const Text("Connect"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 15.0),
                                  child: Image.network(
                                    "https://images.pexels.com/photos/190819/pexels-photo-190819.jpeg?cs=srgb&dl=pexels-ferarcosn-190819.jpg&fm=jpg",
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
