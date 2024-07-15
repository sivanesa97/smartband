import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/Screens/Models/usermodel.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';
import 'package:smartband/Screens/Widgets/string_extensions.dart';

class Profilepage extends ConsumerStatefulWidget {
  const Profilepage({super.key});

  @override
  ConsumerState<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends ConsumerState<Profilepage> {
  bool isEdit = false;
  TextEditingController _contactController = TextEditingController();
  TextEditingController _genderController = TextEditingController();
  TextEditingController _birthdayController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  TextEditingController _weightController = TextEditingController();
  TextEditingController _stepsgoalController = TextEditingController();

  Future<String> getLocation() async {
    Position location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );

    Placemark place = placemarks[0];
    return place.locality ?? 'Unknown location';
  }

  Future<void> getData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      try {
        final data = await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .get();
        if (data.exists) {
          var data1 = data.data();
          print(data1!['phone_number']);
          setState(() {
            _contactController.text = data1!['phone_number'].toString() ?? '';
            _genderController.text = data1!['gender'] ?? '';
            _birthdayController.text = data1!['dob'] ?? '';
            _heightController.text = data1!['height'].toString() ?? '';
            _weightController.text = data1!['weight'].toString() ?? '';
            _stepsgoalController.text =
            data1['steps_goal'].toString();
          });
        } else {
          print('Document does not exist');
        }
      } catch (e) {
        print('Error fetching data: $e');
      }
    } else {
      print('User is not authenticated');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    final user_data =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(),
      body: SingleChildScrollView(
        child: SafeArea(
          child: user_data.when(
            data: (data) {
              final relations = data!.relations;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.45,
                        height: MediaQuery.of(context).size.height * 0.3,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(20)),
                          color: Colors.grey.withOpacity(0.6),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              size: 70.0,
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Text(
                              "Name",
                              style: TextStyle(fontSize: 20),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Email Address",
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: Text(
                                  "${data!.email}",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.orangeAccent),
                                ),
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              Text(
                                "Contact",
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                              isEdit
                                  ? SizedBox(
                                width: 100,
                                height: 40,
                                child: TextFormField(
                                  controller: _contactController,
                                  decoration: InputDecoration(
                                    hintText: data.phone_number.toString(),
                                  ),
                                ),
                              )
                                  : Text(
                                data!.phone_number.toString(),
                                style: TextStyle(fontSize: 16, color: Colors.orangeAccent),
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              Text(
                                "Location",
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: FutureBuilder<String>(
                                  future: getLocation(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text(
                                        'Loading...',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.orangeAccent),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Text(
                                        'Error: ${snapshot.error}',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.orangeAccent),
                                      );
                                    } else if (snapshot.hasData) {
                                      return Text(
                                        snapshot.data ??
                                            'Unknown location',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.orangeAccent),
                                      );
                                    } else {
                                      return Text(
                                        'Unknown location',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.orangeAccent),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    color: Colors.grey.withOpacity(0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            "Emergency Contact",
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 125,
                          child: ListView.builder(
                            itemCount: data!.relations.length,
                            itemBuilder: (context, index) {
                              final relation = data!.relations[index];
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 10.0),
                                margin: EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 5.0),
                                decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(10.0)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      relation,
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 18),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        relations.remove(relation);
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(FirebaseAuth
                                                .instance.currentUser!.uid)
                                            .update({'relations': relations});
                                      },
                                      child: Icon(Icons.delete),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Other Details",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 18),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  isEdit = !isEdit;
                                });
                                if (!isEdit) {
                                  FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(FirebaseAuth.instance.currentUser!.uid)
                                      .update({
                                      "phone_number": int.parse(_contactController.text),
                                      "gender": _genderController.text.toTitleCase(),
                                      "dob": _birthdayController.text,
                                      "height": double.parse(_heightController.text),
                                      "weight": double.parse(_weightController.text),
                                      "steps_goal": int.parse(_stepsgoalController.text)
                                  });
                                  getData();
                                }
                              },
                              child: Icon(
                                isEdit ? Icons.check : Icons.edit,
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Gender",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 18),
                            ),
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: isEdit
                                  ? TextFormField(
                                      controller: _genderController,
                                      decoration: InputDecoration(
                                        hintText: data!.gender,
                                      ),
                                    )
                                  : Text(
                                      data!.gender,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 16),
                                    ),
                            )
                          ],
                        ),
                        Divider(
                          height: 10,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Birthday",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 18),
                            ),
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: isEdit
                                  ? TextFormField(
                                      controller: _birthdayController,
                                      decoration: InputDecoration(
                                        hintText: data!.dob,
                                      ),
                                    )
                                  : Text(
                                      data!.dob,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 16),
                                    ),
                            )
                          ],
                        ),
                        Divider(
                          height: 10,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Height",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 18),
                            ),
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: isEdit
                                  ? TextFormField(
                                      controller: _heightController,
                                      decoration: InputDecoration(
                                        hintText: data!.height.toString(),
                                      ),
                                    )
                                  : Text(
                                      data!.height.toString(),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 16),
                                    ),
                            )
                          ],
                        ),
                        Divider(
                          height: 10,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Weight",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 18),
                            ),
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: isEdit
                                  ? TextFormField(
                                      controller: _weightController,
                                      decoration: InputDecoration(
                                        hintText: data!.weight.toString(),
                                      ),
                                    )
                                  : Text(
                                      data!.weight.toString(),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 16),
                                    ),
                            )
                          ],
                        ),
                        Divider(
                          height: 10,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Steps Goal",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 18),
                            ),
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: isEdit
                                  ? TextFormField(
                                      controller: _stepsgoalController,
                                      decoration: InputDecoration(
                                        hintText: data!.steps_goal.toString(),
                                      ),
                                    )
                                  : Text(
                                      data!.steps_goal.toString(),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 16),
                                    ),
                            )
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
            error: (error, StackTrace) {
              return Text("Error");
            },
            loading: () {
              return CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
