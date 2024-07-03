import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartband/Screens/Widgets/appBarProfile.dart';

class NotConnectedPage extends StatefulWidget {
  const NotConnectedPage({super.key});

  @override
  State<NotConnectedPage> createState() => _NotConnectedPageState();
}

class _NotConnectedPageState extends State<NotConnectedPage> {
  final User? _user = FirebaseAuth.instance.currentUser;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context, rootNavigator: true).pop();
  }

  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> connectedDevices = [];
  List<ScanResult> listDevice = [];
  List<BluetoothDevice> availableDevices = [];
  BluetoothDevice? selectedDevice;

  void getPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse
    ].request();
  }

  void scanForDevices() async {
    try {
      await flutterBlue.startScan(timeout: Duration(seconds: 10));

      flutterBlue.scanResults.listen((List<ScanResult> results) {
        for (ScanResult result in results) {
          print(results);
          listDevice.add(result);
        }
      });

      await Future.delayed(Duration(seconds: 10));
      await flutterBlue.stopScan();
    } catch (e) {
      print('Error scanning for devices: $e');
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        selectedDevice = device;
        connectedDevices.add(device);
      });
      discoverServices(device);
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      print('Service UUID: ${service.uuid}');
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        print('Characteristic UUID: ${characteristic.uuid}');
      }
    }
  }

  void disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      setState(() {
        connectedDevices.remove(device);
        if (selectedDevice == device) {
          selectedDevice = null;
        }
      });
    } catch (e) {
      print('Error disconnecting from device: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getPermissions();
    scanForDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.85),
      appBar: const AppBarProfileWidget(),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text(
              "You have not linked a device",
              style: TextStyle(
                fontSize: 36
              ),
            ),
          ),
          Text(_user?.email ?? "No user signed in"),
          InkWell(
            onTap: () {
              signOut();
            },
            child: const Text("Sign out"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: listDevice.length,
              itemBuilder: (context, index) {
                  // final device = availableDevices[index];
                  return ListTile(
                    title: Text("Device Name"),
                    subtitle: Text("Device ID"),
                    onTap: () {
                      // connectToDevice(device);
                    },
                  );
              },
            ),
          ),
        ],
      ),
    );
  }
}
