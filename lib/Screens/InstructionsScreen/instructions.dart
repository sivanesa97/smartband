import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class InstructionsScreen extends StatefulWidget {
  @override
  _InstructionsScreenState createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(

          mainAxisAlignment: MainAxisAlignment.spaceEvenly,

          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  GestureScreen(
                    imagePath: 'assets/images/gesture1.png', // replace with your actual image path
                    title: 'Please follow the Gestures',
                    description: 'Follow the Gestures to add more Synchronization',
                  ),
                  GestureScreen(
                    imagePath: 'assets/images/gesture2.png',
                    title: 'Gestures',
                    description: 'Starting point: Fist',
                  ),
                  GestureScreen(
                    imagePath: 'assets/images/gesture3.png',
                    title: 'Gestures',
                    description: 'Play: Open little finger & index finger',
                  ),
                  GestureScreen(
                    imagePath: 'assets/images/gesture4.png',
                    title: 'Gestures',
                    description: 'Open Vigour: Open little finger & thumb',
                    isLastPage: true,
                    onNext: () {
                      // Define what happens when the "Get Started" button is pressed
                    },
                  ),
                ],
              ),
            ),
            SmoothPageIndicator(
              controller: _pageController,  // PageController
              count: 4,
              effect: WormEffect(),  // Customize the effect as needed
            ),
          ],
        ),
      ),
    );
  }
}

class GestureScreen extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final bool isLastPage;
  final VoidCallback? onNext;

  GestureScreen({
    required this.imagePath,
    required this.title,
    required this.description,
    this.isLastPage = false,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    imagePath,
                    height: 200.0,
                    width: 200.0,
                  ),
                  SizedBox(height: 20.0),
                  Text(
                    description,
                    style: TextStyle(fontSize: 18.0),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (isLastPage)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: onNext,
                child: Text('Get Started'),
              ),
            ),
        ],
      ),
    );
  }
}


//instructions