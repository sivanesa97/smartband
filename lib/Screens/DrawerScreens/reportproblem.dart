import 'package:flutter/material.dart';
import 'package:smartband/Screens/HomeScreen/settings.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';
import 'package:smartband/Screens/Widgets/drawer.dart';

class Reportproblem extends StatefulWidget {
  final String phNo;
  Reportproblem({super.key, required this.phNo});

  @override
  State<Reportproblem> createState() => _ReportproblemState();
}

class _ReportproblemState extends State<Reportproblem> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarWidget(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Report an issue",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10,),
                const Text(
                    "Reporting an issues will be our gifted thing. Where we can able to rectify and have friendly interface"
                ),
                const SizedBox(height: 20,),
                const Text(
                  "Mail ID",
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
                          "Submit".toUpperCase()
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
