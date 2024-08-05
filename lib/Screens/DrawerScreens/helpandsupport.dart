import 'package:flutter/material.dart';
import 'package:smartband/Screens/HomeScreen/settings.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';
import 'package:smartband/Screens/Widgets/drawer.dart';

class Helpandsupport extends StatefulWidget {
  final String phNo;
  Helpandsupport({super.key, required this.phNo});

  @override
  State<Helpandsupport> createState() => _HelpandsupportState();
}

class _HelpandsupportState extends State<Helpandsupport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerScreen(device: bluetoothDeviceManager.connectedDevices.first, phNo: widget.phNo,),
      appBar: const AppBarWidget(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Contact Info",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10,),
                const Text(
                    "Don't hesitate to get in touch. We will reply you as soon as possible."
                ),
                const SizedBox(height: 20),
                const Text(
                  "Sri Lanka",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10,),
                const Text(
                    "No.218, Brown Road, Jaffna, Sri Lanka. \nTel : 021 2217095 \nE-mail : infor@innovay.com"
                ),
                const SizedBox(height: 20),
                const Text(
                  "United Kingdom",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10,),
                const Text(
                    "SVS House , Oliver Grave , South Norwood, SE25\n6EJ, United Kingdom. \nE-mail : infor@innovay.com"
                ),
                const SizedBox(height: 20,),
                const Text(
                  "Send us a message",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10,),
                const Text(
                  "Name",
                  style: TextStyle(fontSize: 16),
                ),
                TextFormField(
                  maxLines: 1,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10,),
                const Text(
                  "Business Email",
                  style: TextStyle(fontSize: 16),
                ),
                TextFormField(
                  maxLines: 1,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10,),
                const Text(
                  "Provide short description of your requirements",
                  style: TextStyle(fontSize: 16),
                ),
                TextFormField(
                  minLines: 5,
                  maxLines: 20,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10,),
                Align(
                  alignment: Alignment.topCenter,
                  child: ElevatedButton(
                      onPressed: () {},
                      child: Text(
                          "Get In Touch".toUpperCase()
                      ),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white
                      )
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
