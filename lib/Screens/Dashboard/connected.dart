import 'package:flutter/material.dart';

class Connected extends StatelessWidget {
  const Connected({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: height * 0.2,),
            Text("Pairing Successful", style: TextStyle(
              fontSize: width * 0.05
            ),),
            Text("CONNECTED", style: TextStyle(
              fontSize: width * 0.15,
              color: Colors.green,
              fontWeight: FontWeight.bold
            ),),
            Text("Your watch is successfully paired", style: TextStyle(fontSize: width * 0.05),),
            Image.asset(
              "assets/watch.png",
              width: width * 0.8,
              height: width * 0.8,
            ),
            Spacer(),
            Center(
                child: Container(
                  width: width * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Color.fromRGBO(0, 83, 188, 1),
                  ),
                  child: TextButton(
                    onPressed: ()
                    {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Continue',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.05
                      ),
                    ),
                  ),
                )
            ),
            SizedBox(height: height * 0.01,)
          ],
        ),
      ),
    );
  }
}
