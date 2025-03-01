import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trusir/teacher/teacher_bottomnavbar.dart';
import 'package:trusir/teacher/teacher_course.dart';
import 'package:trusir/teacher/teacher_facilities.dart';
import 'package:trusir/teacher/teacher_homepage.dart';

class TeacherMainScreen extends StatefulWidget {
  final int index;
  const TeacherMainScreen({super.key, required this.index});

  @override
  TeacherMainScreenState createState() => TeacherMainScreenState();
}

class TeacherMainScreenState extends State<TeacherMainScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      currentIndex = widget.index;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.grey[50], // Transparent for the homepage
          statusBarIconBrightness:
              Brightness.dark, // White icons for a dark background
        ),
      );
    });
  }

  // List of pages for each bottom navigation item
  final List<Widget> pages = [
    const Teacherhomepage(enableReg: false),
    const TeacherCoursePage(), // Home page (Student Facilities) // Placeholder for Courses
    const TeacherFacilities(),
    // Placeholder for Menu
  ];

  // Function to handle bottom navigation item taps
  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  bottom: currentIndex == 2
                      ? 0
                      : 80), // Adjust for bottom nav bar height
              child: pages[currentIndex],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: TeacherBottomNavigationBar(
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
