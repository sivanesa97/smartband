import 'package:flutter/material.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class InstructionsScreen extends StatefulWidget {
  final VoidCallback onNext;

  const InstructionsScreen({super.key, required this.onNext});

  @override
  _InstructionsScreenState createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: _currentPage == 3 ? 600 : 500,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                GestureScreen(
                  imagePath: 'assets/img0.jpg',
                  title: 'Please follow the Gestures',
                  description:
                      'Follow the Gestures to add more Synchronization',
                ),
                GestureScreen(
                  imagePath: 'assets/img1.jpg',
                  title: 'Gestures',
                  description: 'Starting point: Fist',
                ),
                GestureScreen(
                  imagePath: 'assets/img2.jpg',
                  title: 'Gestures',
                  description: 'Play: Open little finger & index finger',
                ),
                GestureScreen(
                  imagePath: 'assets/img3.jpg',
                  title: 'Gestures',
                  description: 'Open Vigour: Open little finger & thumb',
                  isLastPage: true,
                  onNext: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          _currentPage == 3
              ? SizedBox.shrink()
              : SmoothPageIndicator(
                  controller: _pageController, // PageController
                  count: 4,
                  effect: ScaleEffect(), // Customize the effect as needed
                ),
        ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Container(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    imagePath,
                    width: 250,
                    height: 250,
                  ),
                ],
              ),
            ),
          ),
          if (isLastPage)
            Center(
              child: TextButton(
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
