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
  TextEditingController _nameController = TextEditingController();
  TextEditingController _mailController = TextEditingController();
  TextEditingController _contactController = TextEditingController();
  TextEditingController _birthdayController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  TextEditingController _weightController = TextEditingController();
  TextEditingController _stepsgoalController = TextEditingController();
  String _selectedGender = "";
  DateTime? _selectedDate;

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _birthdayController.text = "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";
      });
    }
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
            _nameController.text= data1['name'] ?? "";
            _mailController.text= data1['email'] ?? "";
            _contactController.text = data1['phone_number'].toString() ?? '';
            _selectedGender = data1['gender'] ?? "Male";
            _birthdayController.text = data1['dob'] ?? '';
            _heightController.text = data1['height'].toString() ?? '';
            _weightController.text = data1['weight'].toString() ?? '';
            _stepsgoalController.text = data1['steps_goal'].toString();
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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final user_data =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: GestureDetector(
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Icon(Icons.arrow_back),
          ),
        ),
        title: Text("Edit Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: user_data.when(
            data: (data) {
              List<String> relations = [];
              if (data != null) {
                relations = data.relations;
              }
              return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
                  child: Container(
                    height: height,
                    child: Column(
                      children: [
                        Center(
                          child: Icon(
                            Icons.account_circle,
                            color: Color.fromRGBO(0, 83, 188, 1),
                            size: width * 0.35,
                          ),
                        ),

                        SizedBox(height: 5,),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Name",
                              style:
                              TextStyle(color: Colors.grey, fontSize: width * 0.04),
                            ),
                            SizedBox(
                              width: width,
                              height: isEdit ? 50 : 40,
                              child: isEdit
                                  ? TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: data!.name,
                                ),
                              )
                                  : Text(
                                data!.name,
                                textAlign: TextAlign.left,
                                style: TextStyle(fontSize: width * 0.05),
                              ),
                            )
                          ],
                        ),

                        SizedBox(height: 5,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Email Address",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: width * 0.04),
                            ),
                            SizedBox(
                              width: width,
                              height: isEdit ? 50 : 40,
                              child: isEdit ?
                              TextFormField(
                                controller: _mailController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: data.email,
                                ),
                              )
                              : Text(
                                data.email,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: width * 0.05, color: Colors.black),
                              ),
                            )
                          ],
                        ),

                        SizedBox(height: 5,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Phone Number",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: width * 0.04),
                            ),
                            SizedBox(
                              width: width,
                              height: isEdit ? 50 : 40,
                              child: isEdit ?
                              TextFormField(
                                controller: _contactController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: data.phone_number.toString(),
                                ),
                              ) : Text(
                                data.phone_number.toString(),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontSize: width * 0.05, color: Colors.black),
                              ),
                            )
                          ],
                        ),

                        if (data.role=='supervisor')
                          SizedBox.shrink()
                        else if (data.role=='watch wearer') ...[
                          SizedBox(height: 5,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Gender",
                                style:
                                TextStyle(color: Colors.grey, fontSize: width * 0.04),
                              ),
                              SizedBox(
                                width: width,
                                height: isEdit ? 50 : 40,
                                child: isEdit
                                    ? Center(
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedGender,
                                      items: ['Male', 'Female', 'Other']
                                          .map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedGender = newValue!;
                                        });
                                      },
                                    ),
                                  ),
                                )
                                    : Text(
                                  data.gender,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: width * 0.05),
                                ),
                              )
                            ],
                          ),

                          SizedBox(height: 5,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Birthday",
                                style:
                                TextStyle(color: Colors.grey, fontSize: width * 0.04),
                              ),
                              SizedBox(
                                width: width,
                                height: isEdit ? 50 : 40,
                                child: isEdit
                                    ? TextFormField(
                                  controller: _birthdayController,
                                  decoration: InputDecoration(
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.calendar_today),
                                      onPressed: () => _selectDate(context),
                                    ),
                                  ),
                                  readOnly: true,
                                )
                                    : Text(
                                  data.dob,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: width * 0.05),
                                ),
                              )
                            ],
                          ),

                          SizedBox(height: 5,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Height",
                                style:
                                TextStyle(color: Colors.grey, fontSize: width * 0.04),
                              ),
                              SizedBox(
                                width: width,
                                height: isEdit ? 50 : 40,
                                child: isEdit
                                    ? TextFormField(
                                  controller: _heightController,
                                  decoration: InputDecoration(
                                    hintText: data.height.toString(),
                                  ),
                                )
                                    : Text(
                                  data.height.toString(),
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: width * 0.05),
                                ),
                              )
                            ],
                          ),

                          SizedBox(height: 5,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Weight",
                                style:
                                TextStyle(color: Colors.grey, fontSize: width * 0.04),
                              ),
                              SizedBox(
                                width: width,
                                height: isEdit ? 50 : 40,
                                child: isEdit
                                    ? TextFormField(
                                  controller: _weightController,
                                  decoration: InputDecoration(
                                    hintText: data.weight.toString(),
                                  ),
                                )
                                    : Text(
                                  data.weight.toString(),
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontSize: width * 0.05),
                                ),
                              )
                            ],
                          ),
                        ],

                        SizedBox(height: 5,),
                        Center(
                            child: Container(
                          width: width * 0.9,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Color.fromRGBO(0, 83, 188, 1),
                          ),
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                isEdit = !isEdit;
                              });
                              if (!RegExp(
                                      r'^(19|20)\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$')
                                  .hasMatch(_birthdayController.text)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Please enter valid date of birth")));
                              }
                              if (_heightController.text.isNotEmpty &&
                                  _weightController.text.isNotEmpty) {
                                try {
                                  double val =
                                      double.parse(_heightController.text);
                                  if (val < 100 && val > 250) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Please enter a valid height")));
                                  }
                                } catch (Exception) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Please enter a valid height")));
                                }
                                try {
                                  double val1 =
                                      double.parse(_weightController.text);
                                } catch (Exception) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Please enter a valid weight")));
                                }
                              }
                              if (!isEdit) {
                                FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .update({
                                  "phone_number":
                                      int.parse(_contactController.text),
                                  "gender":
                                      _selectedGender,
                                  "dob": _birthdayController.text,
                                  "height":
                                      double.parse(_heightController.text),
                                  "weight":
                                      double.parse(_weightController.text),
                                });
                                getData();
                              }
                            },
                            child: !isEdit
                                ? Text(
                                    'Edit',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: width * 0.05),
                                  )
                                : Text(
                                    'Save details',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: width * 0.05),
                                  ),
                          ),
                        )),
                      ],
                    ),
                  ));
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
