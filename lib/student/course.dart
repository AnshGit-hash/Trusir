// course.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/toggle_button.dart';
import 'package:trusir/student/all_courses.dart';
import 'package:trusir/student/main_screen.dart';
import 'package:trusir/student/demo_courses.dart';
import 'package:trusir/student/my_courses.dart';

class Course {
  final int id;
  final int active;
  final String amount;
  final String name;
  final String courseClass;
  final String subject;
  final String pincode;
  final String newAmount;
  final String image;
  final String medium;
  final String board;
  final String student;

  Course({
    required this.id,
    required this.amount,
    required this.active,
    required this.name,
    required this.subject,
    required this.pincode,
    required this.courseClass,
    required this.newAmount,
    required this.image,
    required this.medium,
    required this.student,
    required this.board,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      amount: json['amount'],
      active: json['active'],
      name: json['name'],
      subject: json['subject'],
      courseClass: json['class'],
      pincode: json['pincode'],
      newAmount: json['new_amount'],
      image: json['image'],
      medium: json['medium'] ?? 'N/A',
      student: json['student'] ?? 'all',
      board: json['board'] ?? 'N/A',
    );
  }
}

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  final PageController _pageController = PageController();
  final GlobalKey<FilterSwitchState> _filterSwitchKey =
      GlobalKey<FilterSwitchState>();

  bool _isLoading = true;
  double balance = 0;
  int _selectedIndex = 0;
  bool isWeb = false;

  // Course data
  List<Course> _allCourses = [];
  List<Course> _specialCourses = [];
  List<Map<String, dynamic>> _myCourses = [];
  List<Map<String, dynamic>> _demoCourses = [];
  List<Course> filteredAllCourses = [];
  List<MyCourseModel> _myCourseDetails = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() => _isLoading = true);

      // First get all necessary user data
      final prefs = await SharedPreferences.getInstance();
      final userID = prefs.getString('userID');
      final userPincode = prefs.getString('pincode');
      final userClass = prefs.getString('class');
      final medium = prefs.getString('medium');
      final board = prefs.getString('board');

      // Fetch balance in parallel with courses
      final balanceFuture = _fetchBalance();
      final allCoursesFuture = _fetchAllCourses();
      final myCoursesFuture = _fetchMyCourses(userID);

      // Wait for all parallel operations
      final results =
          await Future.wait([balanceFuture, allCoursesFuture, myCoursesFuture]);

      balance = results[0] as double;
      _allCourses = results[1] as List<Course>;
      _myCourseDetails = results[2] as List<MyCourseModel>;

      // Now filter the courses sequentially
      await _filterMyCourses(userID);
      await _filterDemoCourses(userID);
      await _filterAllCourses(userPincode, userClass, medium, board);
      await _filterSpecialCourses(userID);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Initialization error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _filterMyCourses(String? userID) async {
    if (userID == null) return;

    final myCoursesList = _myCourseDetails
        .where((c) => c.type == 'purchased' || c.type == 'Purchased')
        .toList();
    _myCourses = await _fetchCoursesByIds(myCoursesList);
  }

  Future<void> _filterDemoCourses(String? userID) async {
    if (userID == null) return;

    final demoCoursesList =
        _myCourseDetails.where((c) => c.type == 'demo').toList();
    _demoCourses = await _fetchCoursesByIds(demoCoursesList);
  }

  Future<void> _filterAllCourses(String? userPincode, String? userClass,
      String? medium, String? board) async {
    if (userPincode == null || userClass == null) return;

    filteredAllCourses = _allCourses.where((course) {
      final noMatchingDetail = !_myCourseDetails
          .any((detail) => int.parse(detail.courseID) == course.id);

      if (board == 'N/A') {
        return noMatchingDetail &&
            course.pincode == userPincode &&
            course.active == 1 &&
            course.courseClass == userClass &&
            course.student == 'all';
      } else {
        return noMatchingDetail &&
            course.pincode == userPincode &&
            course.active == 1 &&
            course.courseClass == userClass &&
            course.board == board &&
            course.student == 'all' &&
            course.medium == medium;
      }
    }).toList();
  }

  Future<void> _filterSpecialCourses(String? userID) async {
    if (userID == null) return;

    _specialCourses = _allCourses.where((course) {
      final isPurchased = _myCourseDetails
          .any((myCourse) => int.parse(myCourse.courseID) == course.id);
      return course.student == userID && !isPurchased;
    }).toList();
  }

  Future<double> _fetchBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/get-user/$userID'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final balance = double.parse(data['balance']);
        prefs.setString('wallet_balance', '$balance');
        return balance;
      }
      return 0;
    } catch (e) {
      debugPrint('Balance fetch error: $e');
      return 0;
    }
  }

  Future<List<Course>> _fetchAllCourses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get-courses'));
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List)
            .map((json) => Course.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Fetch all courses error: $e');
      return [];
    }
  }

  Future<List<MyCourseModel>> _fetchMyCourses(String? userID) async {
    if (userID == null) return [];
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/get-courses/$userID'));
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List)
            .map((json) => MyCourseModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Fetch my courses error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCoursesByIds(
      List<MyCourseModel> courses) async {
    final List<Map<String, dynamic>> result = [];
    try {
      for (final course in courses) {
        final data = await _fetchCourseById(course.courseID);
        if (data != null) {
          result.add({
            ...data,
            'teacherID': course.teacherID,
            'slotID': course.id,
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch courses by IDs error: $e');
    }
    return result;
  }

  Future<Map<String, dynamic>?> _fetchCourseById(String courseId) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/get-course-by-id/$courseId"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Fetch course by ID error: $e');
    }
    return null;
  }

  void _onPageChanged(int index) {
    if (_isLoading) {
      return;
    }
    if (_selectedIndex != index && mounted && !_isLoading) {
      setState(() => _selectedIndex = index);
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _filterSwitchKey.currentState?.setSelectedIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MainScreen(index: 2)),
                ),
                child: Image.asset('assets/back_button.png', height: 50),
              ),
              const SizedBox(width: 20),
              const Text(
                'Course',
                style: TextStyle(
                  color: Color(0xFF48116A),
                  fontSize: 25,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 70,
      ),
      body: Column(
        children: [
          FilterSwitch(
            key: _filterSwitchKey,
            option1: 'My Courses',
            option2: 'Demo Courses',
            option3: 'All Courses',
            initialSelectedIndex: _selectedIndex,
            onChanged: (index) {
              if (_isLoading) {
                return;
              }
              _pageController.jumpToPage(
                index,
              );
            },
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      Mycourses(
                          courses: _myCourses, specialCourses: _specialCourses),
                      Democourses(courses: _demoCourses),
                      AllCourses(courses: _allCourses),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

// Simplified model classes for brevity
class MyCourseModel {
  final int id;
  final String courseID;
  final String teacherID;
  final String type;

  MyCourseModel({
    required this.id,
    required this.courseID,
    required this.teacherID,
    required this.type,
  });

  factory MyCourseModel.fromJson(Map<String, dynamic> json) {
    return MyCourseModel(
      id: json['id'],
      courseID: json['courseID'],
      teacherID: json['teacherID'],
      type: json['type'],
    );
  }
}
