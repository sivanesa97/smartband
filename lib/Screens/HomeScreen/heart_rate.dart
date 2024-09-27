import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartband/Providers/OwnerDeviceData.dart';
import 'package:smartband/bluetooth.dart';

import '../Models/usermodel.dart';
import 'package:provider/provider.dart' as provider;
import '../Widgets/drawer.dart';

class HeartrateScreen extends ConsumerStatefulWidget {
  final BluetoothDevice device;
  final String phNo;

  const HeartrateScreen({super.key, required this.device, required this.phNo});

  @override
  ConsumerState<HeartrateScreen> createState() => _HeartrateScreenState();
}

class _HeartrateScreenState extends ConsumerState<HeartrateScreen> {
  final BluetoothDeviceManager bluetoothDeviceManager =
      BluetoothDeviceManager();
  int age = 0;

  @override
  void initState() {
    super.initState();
    _setOwnerDeviceData();
  }

  void _setOwnerDeviceData() async {
    final deviceOwnerData =
        provider.Provider.of<OwnerDeviceData>(context, listen: false);
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      var dob = userData['dob'];
      if (dob != null && dob != '') {
        try {
          DateTime birthdate = DateFormat("yyyy-MM-dd").parse(dob.toString());
          DateTime currentDate = DateTime.now();
          age = currentDate.year - birthdate.year;
          if (currentDate.month < birthdate.month ||
              (currentDate.month == birthdate.month &&
                  currentDate.day < birthdate.day)) {
            age--;
          }
        } catch (e) {
          print(e);
        }
      }
      deviceOwnerData.updateStatus(
          age: age,
          heartRate: deviceOwnerData.heartRate,
          spo2: deviceOwnerData.spo2);
    } else {
      print('User data not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    final deviceOwnerData = provider.Provider.of<OwnerDeviceData>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        drawer: DrawerScreen(
            device: bluetoothDeviceManager.connectedDevices.first,
            phNo: widget.phNo,
            subscription: "",
            status: ""),
        backgroundColor: Colors.white,
        body: userData.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text("User data is unavailable"));
            }
            return SafeArea(
                child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(15),
                          width: width * 0.95,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  "https://img.freepik.com/free-psd/human-organs-character-composition_23-2150610255.jpg?w=740&t=st=1722582551~exp=1722583151~hmac=9063f493678bb77871c62d73d0ebf86776220ef9f1ef77d6d81eac42809654b2",
                                  width: width * 0.4,
                                ),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Health Age",
                                    style: TextStyle(
                                        fontSize: width * 0.05,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        age.toString(),
                                        style: TextStyle(
                                            fontSize: width * 0.1,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "years",
                                        style: TextStyle(
                                            fontSize: width * 0.05,
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: width * 0.4,
                                    child: Text(
                                      "Congrats! You're on a healthier track.",
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: width * 0.03,
                                          color: Colors.white),
                                    ),
                                  )
                                ],
                              )
                            ],
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15.0),
                            child: Text(
                              "Track your Heart Rate",
                              style: TextStyle(
                                  fontSize: width * 0.05,
                                  fontWeight: FontWeight.bold),
                            ),
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                          padding: const EdgeInsets.all(15),
                          width: width * 0.95,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(228, 240, 254, 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Image.asset(
                                    "assets/heart_rate_1.png",
                                    width: width * 0.4,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        deviceOwnerData.heartRate.toString(),
                                        style: TextStyle(fontSize: width * 0.1),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Column(
                                        children: [
                                          const Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                          ),
                                          Text(
                                            "BPM",
                                            style: TextStyle(
                                                fontSize: width * 0.04),
                                          )
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Container(
                                width: width * 0.8,
                                height: height * 0.01,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(colors: [
                                    Colors.green,
                                    Colors.yellow,
                                    Colors.orange,
                                    Colors.red
                                  ], stops: [
                                    0.175,
                                    0.275,
                                    0.35,
                                    1.0
                                  ]),
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 100),
                                child: const Icon(
                                  Icons.arrow_drop_down_sharp,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    "Average",
                                    style: TextStyle(fontSize: width * 0.035),
                                  ),
                                  Text(
                                    "Healthy",
                                    style: TextStyle(fontSize: width * 0.035),
                                  ),
                                  Text(
                                    "Maximum",
                                    style: TextStyle(fontSize: width * 0.035),
                                  ),
                                  Text(
                                    "Danger",
                                    style: TextStyle(fontSize: width * 0.035),
                                  )
                                ],
                              )
                            ],
                          )),
                      const SizedBox(
                        height: 15,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Image.asset(
                          "assets/heart_rate.png",
                          width: width * 0.9,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ));
          },
          error: (error, stackTrace) {
            return const Center(child: Text("Error Fetching User details"));
          },
          loading: () {
            return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent));
          },
        ));
  }
}
