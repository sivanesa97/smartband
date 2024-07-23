import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartband/Screens/Models/usermodel.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';
import 'package:smartband/Screens/Widgets/drawer.dart';

class Emergencycard extends ConsumerStatefulWidget {
  const Emergencycard({super.key});

  @override
  ConsumerState<Emergencycard> createState() => _EmergencycardState();
}

class _EmergencycardState extends ConsumerState<Emergencycard> {
  bool isEdit = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _bloodController = TextEditingController();
  TextEditingController _medicalnotesController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _medicationsController = TextEditingController();
  TextEditingController _organDonorController = TextEditingController();
  TextEditingController _contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getData();
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
          var data1 = data.data()!['emergency'];
          setState(() {
            _nameController.text = data1['name'] ?? '';
            _bloodController.text = data1['blood_group'] ?? '';
            _medicalnotesController.text = data1['medical_notes'] ?? '';
            _addressController.text = data1['address'] ?? '';
            _medicationsController.text = data1['medications'] ?? '';
            _organDonorController.text =
                data1['organ_donor'] == false ? "No" : "Yes";
            _contactController.text = data1['contact'].toString() ?? '';
          });
        } else {
          print('Document does not exist');
        }
      } catch (e) {
        print('Error fetching data: $e');
        // Handle error gracefully, e.g., show a snackbar or alert dialog
      }
    } else {
      print('User is not authenticated');
      // Handle case where user is not authenticated
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergency_data =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.white,
          title: Align(
            alignment: const Alignment(-0.05, 0),
            child: Image.asset(
              "assets/logo.jpg",
              height: 60,
            ),
          )),
      body: SafeArea(
        child: Padding(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.grey),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            "EMERGENCY CARD",
                            style: TextStyle(fontSize: 24, color: Colors.white),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            getData();
                            setState(() {
                              isEdit = !isEdit;
                            });
                            if (!isEdit) {
                              FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .update({
                                "emergency": {
                                  "name": _nameController.text,
                                  "blood_group": _bloodController.text,
                                  "medical_notes": _medicalnotesController.text,
                                  "address": _addressController.text,
                                  "medications": _medicationsController.text,
                                  "organ_donor": _organDonorController.text
                                              .toLowerCase() ==
                                          "yes"
                                      ? true
                                      : false,
                                  "contact": _contactController.text == ""
                                      ? 0
                                      : int.parse(_contactController.text),
                                }
                              });
                            }
                          },
                          child: Icon(
                            isEdit ? Icons.check : Icons.edit,
                            color: Colors.black54,
                          ),
                        )
                      ],
                    ),
                    emergency_data.when(data: (data) {
                      return Padding(
                        padding: EdgeInsets.all(10),
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: Colors.white),
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 7.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      child: Icon(
                                        Icons.account_circle_outlined,
                                        size: 35,
                                        color: Colors.black,
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "NAME",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        SizedBox(
                                            width: 200,
                                            height: 40,
                                            child: isEdit
                                                ? TextFormField(
                                                    controller: _nameController,
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          _nameController.text,
                                                    ),
                                                  )
                                                : Text(
                                                    data?.emergency['name'] ?? "",
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  )),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 7.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      child: Icon(
                                        Icons.water_drop,
                                        color: Colors.black,
                                        size: 35,
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "BLOOD GROUP",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        SizedBox(
                                          width: 200,
                                          height: 40,
                                          child: isEdit
                                              ? TextFormField(
                                                  controller: _bloodController,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        _bloodController.text,
                                                  ),
                                                )
                                              : Text(
                                                  data?.emergency['blood_group'] ?? "",
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 7.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      child: Icon(
                                        Icons.notes,
                                        size: 35,
                                        color: Colors.black,
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "MEDICAL NOTES",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        SizedBox(
                                          width: 200,
                                          height: 40,
                                          child: isEdit
                                              ? TextFormField(
                                                  controller:
                                                      _medicalnotesController,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        _medicalnotesController
                                                            .text,
                                                  ),
                                                )
                                              : Text(
                                                  data?.emergency['medical_notes'] ?? "",
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 7.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      child: Icon(
                                        Icons.home,
                                        size: 35,
                                        color: Colors.black,
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "ADDRESS",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        SizedBox(
                                          width: 200,
                                          height: 40,
                                          child: isEdit
                                              ? TextFormField(
                                                  controller:
                                                      _addressController,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        _addressController.text,
                                                  ),
                                                )
                                              : Text(
                                                  data?.emergency['address'] ?? "",
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 7.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      child: Icon(
                                        Icons.medication,
                                        size: 35,
                                        color: Colors.black,
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "MEDICATIONS",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        SizedBox(
                                          width: 200,
                                          height: 40,
                                          child: isEdit
                                              ? TextFormField(
                                                  controller:
                                                      _medicationsController,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        _medicationsController
                                                            .text,
                                                  ),
                                                )
                                              : Text(
                                                  data?.emergency['medications'] ?? "",
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 7.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      child: Icon(
                                        Icons.favorite,
                                        size: 35,
                                        color: Colors.black,
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "ORGAN DONOR",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        SizedBox(
                                          width: 200,
                                          height: 40,
                                          child: isEdit
                                              ? TextFormField(
                                                  controller:
                                                      _organDonorController,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        _organDonorController
                                                            .text,
                                                  ),
                                                )
                                              : Text(
                                                  data?.emergency['organ_donor'] ==
                                                          true
                                                      ? "Yes"
                                                      : "No",
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 7.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      child: Icon(
                                        Icons.phone,
                                        size: 35,
                                        color: Colors.black,
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "CONTACT",
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        SizedBox(
                                          width: 200,
                                          height: 40,
                                          child: isEdit
                                              ? TextFormField(
                                                  controller:
                                                      _contactController,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        _contactController.text,
                                                  ),
                                                )
                                              : Text(
                                                  data?.emergency['contact'].toString() ?? "",
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, error: (error, StackTrace) {
                      return Text("Error fetching data");
                    }, loading: () {
                      return CircularProgressIndicator();
                    })
                  ],
                ),
              ),
            )),
      ),
    );
  }
}
