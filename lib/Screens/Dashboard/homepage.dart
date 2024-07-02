import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartband/Screens/AuthScreen/signin.dart';
import 'package:smartband/Screens/SplashScreen/splash.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> connectedDevices = [];
  BluetoothDevice? selectedDevice;
  String? stepsCount;

  @override
  void initState() {
    super.initState();
    getPermissions();
    scanForDevices();
  }

  void getPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse
    ].request();
  }

  void scanForDevices() async {
    var devices = await flutterBlue.connectedDevices;
    setState(() {
      connectedDevices = devices;
    });
  }
  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      selectedDevice = device;
    });
    discoverServices(device);
  }

  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      print('Service UUID: ${service.uuid}');
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        print('Characteristic UUID: ${characteristic.uuid}');
        var value = await characteristic.value;
      }
    }
  }


  final User? _user = FirebaseAuth.instance.currentUser;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(
            height: 300,
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
              itemCount: connectedDevices.length,
              itemBuilder: (context, index) {
                final device = connectedDevices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.id.toString()),
                  onTap: () => discoverServices(device),
                );
              },
            ),
          ),
          Text(
            "Steps count : $stepsCount"
          )
        ],
      ),
    );
  }
}
