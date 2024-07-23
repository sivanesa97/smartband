import 'package:flutter/material.dart';
import 'package:smartband/Screens/HomeScreen/notifications.dart';
import 'package:smartband/Screens/HomeScreen/upgrade.dart';
import 'package:smartband/Screens/Widgets/appBarProfile.dart';
import 'package:smartband/Screens/Widgets/drawer.dart';
import 'package:smartband/bluetooth.dart';

BluetoothDeviceManager bluetoothDeviceManager = BluetoothDeviceManager();

class Settingscreen extends StatefulWidget {
  String device_name;
  String mac_address;
  Settingscreen({super.key, required this.device_name, required this.mac_address});

  @override
  State<Settingscreen> createState() => _SettingscreenState();
}

class _SettingscreenState extends State<Settingscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarProfileWidget(),
      drawer: const DrawerScreen(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: Colors.grey.withOpacity(0.5),
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.device_name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.mac_address,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.toggle_on, size: 40),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              print("DIsconnect : ${bluetoothDeviceManager.connectedDevices}");
                              bluetoothDeviceManager.disconnectFromDevice();
                              // bluetoothDeviceManager.connectedDevices = [];
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.white),
                            child: Text('Remove'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                Image.network(
                  "https://placements.lk/storage/Company/LogoImages/1637824455.jpg",
                  width: 100,
                ),
                // Replace with your watch image asset
              ],
            ),
          ),
          Container(
            color: Colors.grey.withOpacity(0.5),
            child: ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notification'),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        maintainState: true,
                        builder: (context) => Notificationscreen()));
              },
            ),
          ),
          Container(
            color: Colors.grey.withOpacity(0.5),
            child: ListTile(
              leading: Icon(Icons.access_alarm),
              title: Text('Alarms'),
              onTap: () {
                // Handle alarms tap
              },
            ),
          ),
          Container(
            color: Colors.grey.withOpacity(0.5),
            child: ListTile(
              leading: Icon(Icons.system_update),
              title: Text('Upgrade'),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        maintainState: true,
                        builder: (context) => Upgradescreen()));
              },
            ),
          )
        ],
      ),
    );
  }
}
