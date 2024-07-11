import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../InstructionsScreen/instructions.dart';
import '../Widgets/appBar.dart';
import '../Widgets/appBarProfile.dart';
import 'dashboard.dart';

class NotConnectedPage extends StatefulWidget {
  const NotConnectedPage({super.key});

  @override
  State<NotConnectedPage> createState() => _NotConnectedPageState();
}

class _NotConnectedPageState extends State<NotConnectedPage> {
  List<BluetoothDevice> connectedDevices = [];
  List<ScanResult> listDevice = [];
  BluetoothDevice? selectedDevice;
  bool addDeviceBtn = false;
  String search_text = "Search for smartwatch";

  @override
  void initState() {
    super.initState();
    var subscription = FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      print(state);
    });
    if (Platform.isAndroid) {
    FlutterBluePlus.turnOn();
    }
    subscription.cancel();
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        selectedDevice = device;
        connectedDevices.add(device);
      });

      final bsSubscription = device.bondState.listen((value) {
        print("$value prev:{$device.prevBondState}");
      });
      device.cancelWhenDisconnected(bsSubscription);
      await device.createBond();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InstructionsScreen(
            onNext: () {
              print("Finished Instructions");
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            },
          ),
        ),
      );
      print("Connected to device: ${device.name}");
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      if (mounted) {
        setState(() {
          connectedDevices.remove(device);
          if (selectedDevice == device) {
            selectedDevice = null;
          }
        });
      }
    } catch (e) {
      print('Error disconnecting from device: $e');
    }
  }

  void scanForDevices() {
    if (mounted) {
      try {
        FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
        print("Scan started");
        FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
          setState(() {
            search_text = "Searching for smartwatch...";
            listDevice.clear();
            listDevice.addAll(results);
          });
        });

        Future.delayed(const Duration(seconds: 15), () {
          FlutterBluePlus.stopScan();
          setState(() {
            search_text = "Search for smartwatch";
          });
        });
      } catch (e) {
        print('Error scanning for devices: $e');
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bluetooth Error'),
        content: const Text('Please turn on Bluetooth first'),
        actions: <Widget>[
          TextButton(
            child: const Text('Got it'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
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
      appBar: addDeviceBtn ? const AppBarWidget() : const AppBarProfileWidget(),
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
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    "Add a Device",
                    style: const TextStyle(
                      color: Colors.white,
                      backgroundColor: Colors.black26,
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
            padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: Text(
              "Add device",
              style: TextStyle(fontSize: 30),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 60.0, vertical: 10.0),
            child: Text(
              "Please select your smartwatch in the list",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Center(
            child: InkWell(
              onTap: () {
                scanForDevices();
              },
              child: Text(
                search_text,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              itemCount: listDevice.length,
              itemBuilder: (context, index) {
                final device = listDevice[index];
                if (device.device.name.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
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
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: width * 0.5,
                                  child: Text(
                                    device.device.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: width * 0.5,
                                  child: Text(
                                    device.device.id.toString(),
                                    style: const TextStyle(fontSize: 17),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: width * 0.3,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      connectToDevice(device.device);
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
