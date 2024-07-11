import 'package:flutter/material.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Drawer(
        width: width * 0.65,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: Image.network(
                  "https://placements.lk/storage/Company/LogoImages/1637824455.jpg",
                  width: 75,
                ),
              ),
              const ListTile(
                leading: Icon(Icons.info, color: Colors.black26,),
                title: Text("About Us"),
              ),
              const ListTile(
                leading: Icon(Icons.assignment, color: Colors.black26,),
                title: Text("Emergency Card"),
              ),
              const ListTile(
                leading: Icon(Icons.help, color: Colors.black26,),
                title: Text("Help and Support"),
              ),
              SizedBox(
                height: height * 0.5,
              ),
              const ListTile(
                leading: Icon(Icons.warning, color: Colors.black26,),
                title: Text("Report an issue"),
              ),
            ],
          ),
        ));
  }
}
