import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Models/usermodel.dart';

class ManageAccess extends ConsumerStatefulWidget {
  String phNo;

  ManageAccess({super.key, required this.phNo});

  @override
  ConsumerState<ManageAccess> createState() => _ManageAccessState();
}

class _ManageAccessState extends ConsumerState<ManageAccess> {
  String? _selectedRole = "supervisor";
  final TextEditingController _phoneConn = TextEditingController();
  final TextEditingController _otpConn = TextEditingController();

  void _showRoleDialog() {
    print(widget.phNo);
    bool sent = false;
    int otp_num = 100000 + Random().nextInt(999999 - 100000 + 1);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add Supervisor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _selectedRole == "supervisor"
                        ? TextFormField(
                      controller: _phoneConn,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Phone Number',
                          suffixIcon: IconButton(
                              onPressed: () {
                                sent = true;
                                _fetchPhoneDetails(
                                    _phoneConn.text, otp_num);
                              },
                              icon:
                              Icon(sent ? Icons.check : Icons.send))),
                    )
                        : const SizedBox.shrink(),
                    const SizedBox(height: 16),
                    _selectedRole == "supervisor"
                        ? TextFormField(
                      controller: _otpConn,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'OTP',
                      ),
                    )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    _showSupervisorDialog(otp_num);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSupervisorDialog(int otp_num) async {
    if (_phoneConn.text != widget.phNo) {
      // _otpConn.text == otp_num.toString()) {
      String phonetoCheck = _phoneConn.text;
      var usersCollection = FirebaseFirestore.instance.collection("users");
      var querySnapshot =
      await usersCollection.where(
          'phone_number', isEqualTo: int.parse(phonetoCheck)).get();
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference
            .update({
          "relations": FieldValue.arrayUnion([widget.phNo.toString()])
        });

        Navigator.of(context, rootNavigator: true).pop();
      } else {
        // Handle email not existing case
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Phone number does not exist in the collection.")));
      }
    }
    else if (_phoneConn.text==widget.phNo) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter a different number")));
    }
    else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchRelationDetails(String phNo) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('relations', arrayContains: phNo)
        .snapshots()
        .map((QuerySnapshot query) {
      List<Map<String, dynamic>> relationDetails = [];
      for (var doc in query.docs) {
        relationDetails.add(doc.data() as Map<String, dynamic>);
      }
      return relationDetails;
    });
  }


  Future<List<Map<String, dynamic>>> _fetchPhoneDetails(String phone_number,
      int otp_num) async {
    List<Map<String, dynamic>> relationDetails = [];
    bool madeCall = false;
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('phone_number', isEqualTo: int.parse(phone_number))
        .get();
    if (userDoc.docs.isNotEmpty) {
      // print(userDoc.docs);
      final data = userDoc.docs.first.data()['phone_number'];
      // await twilioService.sendSms('+91${data}', 'Your OTP is ${otp_num}');
    }
    return relationDetails;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery
        .of(context)
        .size
        .width;
    final height = MediaQuery
        .of(context)
        .size
        .height;
    final userData =
    ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: Align(
          alignment: Alignment.center,
          child: Text(
            "Manage Access",
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(width: width * 0.6),
                  Text(
                    "Edit",
                    style: TextStyle(
                      fontSize: width * 0.04,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: width * 0.04),
                  Text(
                    "Delete",
                    style: TextStyle(
                      fontSize: width * 0.04,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: width * 0.04),
                  Text(
                    "Status",
                    style: TextStyle(
                      fontSize: width * 0.04,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
              userData.when(
                data: (data) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _fetchRelationDetails(widget.phNo.toString()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(
                          color: Color.fromRGBO(0, 83, 188, 1),
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      var details = snapshot.data!;
                      return Column(
                        children: [
                          Container(
                            height: height * 0.75,
                            child: ListView.builder(
                              itemCount: details.length,
                              itemBuilder: (context, index) {
                                final relationDetail = details[index];
                                final relationName = relationDetail['name'];
                                return Container(
                                  padding: EdgeInsets.only(
                                      left: 10.0, top: 10.0, bottom: 10.0),
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 15.0,
                                    vertical: 5.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.account_circle,
                                          color: Color.fromRGBO(0, 83, 188, 1),
                                          size: width * 0.1,
                                        ),
                                      ),
                                      SizedBox(
                                        width: width * 0.01,
                                      ),
                                      SizedBox(
                                        width: width * 0.4,
                                        child: Text(
                                          relationName,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: width * 0.02,
                                      ),
                                      const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                      ),
                                      SizedBox(
                                        width: width * 0.05,
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final data = await FirebaseFirestore.instance
                                              .collection('users')
                                              .where('name', isEqualTo: relationName)
                                              .where('relations', arrayContains: widget.phNo)
                                              .get();
                                          data.docs.first.reference.update({'relations' : FieldValue.arrayRemove([widget.phNo])});
                                        },
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                      ),
                                      SizedBox(
                                        width: width * 0.06,
                                      ),
                                      Icon(
                                        Icons.toggle_on,
                                        color: Colors.green,
                                        size: width * 0.1,
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _showRoleDialog();
                            },
                            child: Container(
                              width: width * 0.9,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                  color: Color.fromRGBO(0, 83, 188, 1),
                                  borderRadius: BorderRadius.circular(30)
                              ),
                              child: Text(
                                "Add Members",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white,
                                    fontSize: width * 0.05),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  );
                },
                error: (error, stackTrace) {
                  return Center(child: Text("Error: $error"));
                },
                loading: () {
                  return CircularProgressIndicator(
                    color: Color.fromRGBO(0, 83, 188, 1),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
