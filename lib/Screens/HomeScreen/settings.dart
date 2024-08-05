import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartband/Screens/AuthScreen/phone_number.dart';
import 'package:smartband/Screens/DrawerScreens/aboutus.dart';
import 'package:smartband/Screens/DrawerScreens/reportproblem.dart';
import 'package:smartband/Screens/HomeScreen/manage_access.dart';
import 'package:smartband/Screens/HomeScreen/notifications.dart';
import 'package:smartband/Screens/HomeScreen/upgrade.dart';
import 'package:smartband/Screens/Widgets/appBarProfile.dart';
import 'package:smartband/Screens/Widgets/drawer.dart';
import 'package:smartband/bluetooth.dart';

BluetoothDeviceManager bluetoothDeviceManager = BluetoothDeviceManager();

class Settingscreen extends StatefulWidget {
  String device_name;
  String mac_address;
  String phNo;
  Settingscreen({super.key, required this.device_name, required this.mac_address, required this.phNo});

  @override
  State<Settingscreen> createState() => _SettingscreenState();
}

class _SettingscreenState extends State<Settingscreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: const AppBarProfileWidget(),
      drawer: DrawerScreen(device: bluetoothDeviceManager.connectedDevices.first, phNo: widget.phNo,),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Color.fromRGBO(0, 83, 188, 1),
              ),
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device_name,
                        style: TextStyle(
                          fontSize: width * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.mac_address,
                        style: TextStyle(
                          fontSize: width * 0.04,
                          color: Colors.white
                        ),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            print("Disconnect : ${bluetoothDeviceManager.connectedDevices}");
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
                          child: Text('Remove', style: TextStyle(
                            color: Color.fromRGBO(0, 83, 188, 1),
                          ),),
                        ),
                      ),
                    ],
                  ),
                  Image.asset(
                    "assets/watch.png",
                    width: width * 0.33,
                  ),
                  // Replace with your watch image asset
                ],
              ),
            ),
          ),
          Container(
            child: ListTile(
              leading: Icon(Icons.supervisor_account, color: Colors.grey),
              title: Text('Manage Access', style: TextStyle(
                color: Color.fromRGBO(0, 83, 188, 1),
              ),),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        maintainState: true,
                        builder: (context) => ManageAccess(phNo: widget.phNo,)));
              },
            ),
          ),
          Container(
            child: ListTile(
              leading: Icon(Icons.system_update, color: Colors.grey),
              title: Text('Upgrade', style: TextStyle(
                color: Color.fromRGBO(0, 83, 188, 1),
              ),),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        maintainState: true,
                        builder: (context) => Upgradescreen()));
              },
            ),
          ),
          Container(
            child: ListTile(
              leading: Icon(Icons.access_alarm, color: Colors.grey),
              title: Text('About Us', style: TextStyle(
                color: Color.fromRGBO(0, 83, 188, 1),
              ),),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        maintainState: true,
                        builder: (context) => Aboutus(phNo: widget.phNo,)));
              },
            ),
          ),
          Container(
            child: ListTile(
              leading: Icon(Icons.warning, color: Colors.grey),
              title: Text('Report an issue', style: TextStyle(
                color: Color.fromRGBO(0, 83, 188, 1),
              ),),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        maintainState: true,
                        builder: (context) => Reportproblem(phNo: widget.phNo,)));
              },
            ),
          ),
          Spacer(),
          Container(
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.grey),
              title: Text('Sign out', style: TextStyle(
                color: Color.fromRGBO(0, 83, 188, 1),
              ),),
              onTap: () async {
                Navigator.of(context, rootNavigator: true)
                    .pushAndRemoveUntil(MaterialPageRoute(
                    builder: (context) => PhoneSignIn()), (Route<dynamic> route) => false);
                final GoogleSignIn googleSignIn = GoogleSignIn();
                await googleSignIn.signOut();
                await FirebaseAuth.instance.signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}
