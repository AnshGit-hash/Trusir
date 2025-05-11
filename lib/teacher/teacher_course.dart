import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/teacher/teacher_facilities.dart';
import 'package:trusir/teacher/teacher_main_screen.dart';

class MyCourseModel {
  final int id;
  final String courseID;
  final String courseName;
  final String teacherName;
  final String teacherID;
  final String studentID;
  final String image;
  final String studentName;
  final String timeSlot;
  final String type;
  final String price;
  final String startDate;

  MyCourseModel(
      {required this.id,
      required this.courseID,
      required this.courseName,
      required this.teacherName,
      required this.teacherID,
      required this.studentID,
      required this.image,
      required this.studentName,
      required this.timeSlot,
      required this.type,
      required this.price,
      required this.startDate});

  factory MyCourseModel.fromJson(Map<String, dynamic> json) {
    return MyCourseModel(
        id: json['id'],
        courseID: json['courseID'],
        courseName: json['courseName'],
        teacherName: json['teacherName'],
        teacherID: json['teacherID'],
        studentID: json['StudentID'],
        image: json['image'],
        studentName: json['StudentName'],
        timeSlot: json['timeSlot'],
        type: json['type'],
        price: json['price'],
        startDate: json['created_at']);
  }
}

class TeacherCourseCard extends StatelessWidget {
  final MyCourseModel course;
  final bool isWeb;

  const TeacherCourseCard({
    super.key,
    required this.course,
    this.isWeb = false,
  });

  @override
  Widget build(BuildContext context) {
    String formatDate(String dateString) {
      DateTime dateTime = DateTime.parse(dateString);
      String formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
      return formattedDate;
    }

    String formatPrice(double price) {
      return price.toStringAsFixed(2); // Ensures exactly 2 decimal places
    }

    String capitalizeFirstLetter(String text) {
      if (text.isEmpty) return text;
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        top: 5.0,
        left: isWeb ? 8 : 16,
        right: isWeb ? 8 : 16,
        bottom: isWeb ? 8 : 4, // Reduced bottom padding for mobile
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Colors.grey[850]!, Colors.grey[900]!]
                  : [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding:
                EdgeInsets.all(isWeb ? 16.0 : 8), // Reduced padding for mobile
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Image with Name (unchanged)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          course.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey[500],
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.deepPurple,
                              Colors.pinkAccent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course.courseName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins",
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8), // Consistent spacing

                // Course Details
                Text(
                  'Start from - ${formatDate(course.startDate)}',
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14, // Slightly smaller on mobile
                    fontFamily: 'Poppins',
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),

                const SizedBox(height: 4), // Reduced spacing

                Text(
                  'Time Slot: ${course.timeSlot}',
                  style: TextStyle(
                    fontSize: isWeb ? 15 : 13, // Slightly smaller on mobile
                    fontFamily: 'Poppins',
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),

                const SizedBox(height: 8), // Consistent spacing

                // Price and Type
                Row(
                  children: [
                    Text(
                      '₹${formatPrice(double.parse(course.price))}', // Formatted price
                      style: TextStyle(
                        fontSize: isWeb ? 24 : 20, // Slightly smaller on mobile
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWeb ? 24 : 16, // Reduced on mobile
                          vertical: isWeb ? 20 : 0, // Reduced on mobile
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.deepPurpleAccent,
                      ),
                      child: Text(
                        capitalizeFirstLetter(course.type), // Capitalized text
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize:
                              isWeb ? 15 : 13, // Slightly smaller on mobile
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TeacherCoursePage extends StatefulWidget {
  const TeacherCoursePage({super.key});

  @override
  State<TeacherCoursePage> createState() => _TeacherCoursePageState();
}

class _TeacherCoursePageState extends State<TeacherCoursePage> {
  final apiBase = '$baseUrl/my-student';
  List<MyCourseModel> courses = [];
  List<StudentProfile> studentprofile = [];
  bool _isLoading = true;

  Future<void> fetchStudentProfiles({int page = 1}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userID = prefs.getString('id');
      final url = '$apiBase/$userID';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          studentprofile =
              data.map((json) => StudentProfile.fromJson(json)).toList();
        });
      } else if (response.statusCode == 201) {
        setState(() {
          studentprofile = [];
        });
      } else {
        throw Exception('Failed to load student profiles');
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, 'Error loading student profiles: $e');
      }
    }
  }

  Future<List<MyCourseModel>> fetchCourses(String userID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? teacherID = prefs.getString('id');

      final url = Uri.parse('$baseUrl/get-courses/$userID');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final List<MyCourseModel> responseData = data
            .map((json) => MyCourseModel.fromJson(json))
            .where((course) => course.teacherID == teacherID)
            .toList();

        if (mounted) {
          setState(() {
            courses = responseData;
            _isLoading = false;
          });
        }
        return courses;
      } else {
        throw Exception('Failed to fetch courses');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showCustomToast(context, 'Error loading courses: $e');
      }
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  void initializeData() async {
    await fetchStudentProfiles();
    if (studentprofile.isNotEmpty && mounted) {
      await fetchCourses(studentprofile[0].userID);
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: EdgeInsets.only(left: isWeb ? 20.0 : 10.0),
          child: Row(
            children: [
              if (!isWeb) // Only show back button on mobile
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherMainScreen(
                          index: 0,
                        ),
                      ),
                    );
                  },
                  child: Image.asset('assets/back_button.png', height: 50),
                ),
              if (!isWeb) const SizedBox(width: 20),
              Text(
                'Course',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: isWeb ? 28 : 25,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: isWeb ? 80 : 70,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isWeb ? 60 : 50),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWeb ? 20.0 : 8.0,
              vertical: 6,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
              child: studentprofile.isEmpty
                  ? Center(
                      child: Text(
                        'No Students Assigned yet',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          studentprofile.length,
                          (index) => Container(
                            margin:
                                EdgeInsets.symmetric(horizontal: isWeb ? 8 : 4),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                    horizontal: isWeb ? 24 : 20,
                                    vertical: isWeb ? 14 : 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                });
                                fetchCourses(studentprofile[index].userID);
                              },
                              child: Text(
                                studentprofile[index].name,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isWeb ? 16 : 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : courses.isEmpty
              ? Center(
                  child: Text(
                    'No Courses Available',
                    style: TextStyle(
                      fontSize: isWeb ? 20 : 18,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1200
                        ? 3
                        : constraints.maxWidth > 800
                            ? 2
                            : 1;
                    final childAspectRatio =
                        constraints.maxWidth > 800 ? 16 / 14 : 16 / 14.5;

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        mainAxisSpacing: isWeb ? 20 : 10,
                        crossAxisSpacing: isWeb ? 20 : 0,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: isWeb ? 20 : 0,
                      ),
                      shrinkWrap: true,
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return TeacherCourseCard(
                          course: course,
                          isWeb: isWeb,
                        );
                      },
                    );
                  },
                ),
    );
  }
}
