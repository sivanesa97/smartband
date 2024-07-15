import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';

class Upgradescreen extends StatelessWidget {
  const Upgradescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Upgrade",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10.0)),
              ),
              const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Looks like there is no update\nYour are updated till date",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18
                        ),
                    ),
                    ]
                  )
              )
            ],
          ),
        ),
      ),
    );
  }
}
