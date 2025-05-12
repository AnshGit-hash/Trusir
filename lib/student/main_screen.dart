import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trusir/student/bottom_navigation_bar.dart';
import 'package:trusir/student/course.dart';
import 'package:trusir/student/student_facilities.dart';
import 'package:trusir/student/student_homepage.dart';

class MainScreen extends StatefulWidget {
  final int index;
  const MainScreen({super.key, required this.index});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.index;
  }

  // List of pages for each bottom navigation item
  final List<Widget> pages = [
    const StudentHomepage(enablephone: false, enableReg: false),
    const CoursePage(),
    const Studentfacilities(),
  ];

  // Function to handle bottom navigation item taps
  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.grey[50],
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            // Main content with proper bottom padding
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 80), // Space for bottom nav
              child: pages[currentIndex],
            ),
            // Bottom navigation bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNavigationBar(
                currentIndex: currentIndex,
                onTap: onTabTapped,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
