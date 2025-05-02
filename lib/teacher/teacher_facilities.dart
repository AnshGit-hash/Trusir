import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/teacher/notice_teacher.dart';
import 'package:trusir/teacher/gk_teacher.dart';
import 'package:trusir/teacher/student_profile.dart';
import 'package:trusir/teacher/teacher_fee_payment.dart';
import 'package:trusir/teacher/teacher_notice.dart';
import 'package:trusir/teacher/teacher_pf_page.dart';
import 'package:trusir/teacher/teacherattendance.dart';
import 'package:trusir/teacher/teacherssettings.dart';
import 'package:trusir/common/wanna_logout.dart';
import '../common/custom_toast.dart';

class StudentProfile {
  final String name;
  final String image;
  final int active;
  final String phone;
  final String subject;
  final String userID;
  final String studentClass;
  final String school;
  final String dob;
  final String address;

  StudentProfile(
      {required this.name,
      required this.image,
      required this.active,
      required this.phone,
      required this.subject,
      required this.userID,
      required this.dob,
      required this.school,
      required this.address,
      required this.studentClass});

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
        name: json['name'],
        image: json['profile'],
        phone: json['phone'],
        active: json['active'],
        subject: json['subject'],
        userID: json['userID'],
        studentClass: json['class'],
        dob: json['father_name'],
        school: json['school'],
        address: json['address']);
  }
}

class TeacherFacilities extends StatefulWidget {
  const TeacherFacilities({super.key});

  @override
  State<TeacherFacilities> createState() => _TeacherFacilitiesState();
}

class _TeacherFacilitiesState extends State<TeacherFacilities> {
  List<StudentProfile> studentprofile = [];
  String name = '';
  String address = '';
  String phone = '';
  String profile = '';
  String userID = '';
  String area = '';
  bool isWeb = false;

  final apiBase = '$baseUrl/my-student';

  Future<void> fetchStudentProfiles({int page = 1}) async {
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
      studentprofile = [];
    } else {
      throw Exception('Failed to load student profiles');
    }
  }

  final List<Color> cardColors = [
    const Color.fromARGB(255, 170, 224, 249),
    const Color.fromARGB(255, 248, 169, 227),
    const Color.fromARGB(255, 109, 216, 249),
    const Color.fromARGB(255, 222, 151, 255),
    const Color.fromARGB(255, 188, 180, 255),
    const Color.fromARGB(255, 235, 177, 236),
  ];

  final Map<String, Map<String, double>> imageSizes = {
    'assets/myprofile.png': {'width': 50, 'height': 50},
    'assets/teacherprofile.png': {'width': 50, 'height': 49},
    'assets/attendance.png': {'width': 44, 'height': 46},
    'assets/money.png': {'width': 51, 'height': 32},
    'assets/pencil and ruller.png': {'width': 31, 'height': 44},
    'assets/medal.png': {'width': 33, 'height': 50},
    'assets/qna.png': {'width': 53, 'height': 53},
    'assets/sir.png': {'width': 46, 'height': 46},
    'assets/knowledge.png': {'width': 44, 'height': 46},
    'assets/notice.png': {'width': 43, 'height': 43},
    'assets/setting.png': {'width': 52, 'height': 52},
    'assets/video knowledge.png': {'width': 85, 'height': 74},
  };

  @override
  void initState() {
    super.initState();
    fetchProfileData();
    fetchStudentProfiles();
  }

  Future<void> fetchProfileData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userID')!;
      name = prefs.getString('name')!;
      profile = prefs.getString('profile')!;
      address = prefs.getString('city')!;
      phone = prefs.getString('phone_number')!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    isWeb = screenWidth > 800; // Increased threshold for web detection

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Teacher Facilities',
          style: TextStyle(
            color: const Color(0xFF48116A),
            fontSize: isWeb ? 26 : 22,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => WanaLogout(profile: profile)),
              );
            },
            child: Padding(
              padding: EdgeInsets.only(top: 0, right: isWeb ? 40.0 : 20.0),
              child: Image.asset(
                'assets/logout@3x.png',
                width: isWeb ? 120 : 103,
                height: isWeb ? 30 : 24,
              ),
            ),
          ),
        ],
        toolbarHeight: isWeb ? 80 : 60,
      ),
      body: isWeb ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildWebLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column - Profile Card and Tiles
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildProfileCard(web: true),
                const SizedBox(height: 30),
                _buildTilesGrid(web: true),
              ],
            ),
          ),
          const SizedBox(width: 30),
          // Right Column - Student Profiles
          Expanded(
            flex: 2,
            child: _buildStudentProfilesSection(web: true),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildProfileCard(web: false),
            const SizedBox(height: 20),
            _buildTilesGrid(web: false),
            const SizedBox(height: 20),
            _buildStudentProfilesSection(web: false),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard({required bool web}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Teacherpfpage()),
        );
      },
      child: Container(
        height: web ? 160 : 116,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF48116A), Color(0xFFC22054)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC22054).withOpacity(0.2),
              spreadRadius: 3,
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    left: web ? 40 : 20, top: 12, bottom: 12, right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: web ? 26 : 22,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      address,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: web ? 20 : 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: Colors.white,
                        fontSize: web ? 18 : 11,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: web ? 40 : 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white12,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.network(
                    profile,
                    width: web ? 130 : 75,
                    height: web ? 130 : 75,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: web ? 60 : 50,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTilesGrid({required bool web}) {
    final crossAxisCount = web ? 4 : 3;
    final childAspectRatio = web ? 1.1 : 0.85;
    final spacing = web ? 30.0 : 15.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: [
        _buildTile(context, const Color.fromARGB(255, 170, 224, 249),
            'assets/myprofile.png', 'My Profile', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Teacherpfpage()),
          );
        }, web),
        _buildTile(context, const Color.fromARGB(255, 248, 169, 227),
            'assets/noticesp@3x.png', 'Notice', () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const TeacherNoticeScreen()),
          );
        }, web),
        _buildTile(
            context,
            const Color.fromARGB(255, 109, 216, 249),
            'assets/money.png',
            'Fee Payment',
            studentprofile.isEmpty
                ? () {
                    showCustomToast(
                        context, "We will assign you a student shortly.");
                  }
                : () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherFeePaymentScreen(),
                        ));
                  },
            web),
        _buildTile(context, const Color.fromARGB(255, 222, 151, 255),
            'assets/setting.png', 'Setting', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Teacherssettings()),
          );
        }, web),
        _buildTile(
            context,
            const Color.fromARGB(255, 188, 180, 255),
            'assets/list@3x.png',
            'Attendance',
            studentprofile.isEmpty
                ? () {
                    showCustomToast(
                        context, 'We will assign you a student shortly.');
                  }
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeacherAttendancePage(
                            studentprofile: studentprofile),
                      ),
                    );
                  },
            web),
        _buildTile(
            context,
            const Color.fromARGB(255, 235, 177, 236),
            'assets/knowledge.png',
            'General Knowledge',
            studentprofile.isEmpty
                ? () {
                    showCustomToast(
                        context, 'We will assign you a student shortly.');
                  }
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddGkTeacher(studentprofile: studentprofile),
                      ),
                    );
                  },
            web),
        if (!web)
          _buildTile(
              context,
              const Color.fromARGB(255, 151, 177, 255),
              'assets/pensp@3x.png',
              'Student Notice',
              studentprofile.isEmpty
                  ? () {
                      showCustomToast(
                          context, 'We will assign you a student shortly.');
                    }
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddNoticeTeacher(studentprofile: studentprofile),
                        ),
                      );
                    },
              web),
      ],
    );
  }

  Widget _buildStudentProfilesSection({required bool web}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: web ? 10 : 5, bottom: 10),
          child: Text(
            'Student Profiles',
            style: TextStyle(
              fontSize: web ? 24 : 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        SizedBox(
          height: web ? 500 : 340,
          child: studentprofile.isEmpty
              ? Center(
                  child: Text(
                    'No Students Enrolled for Any course yet',
                    style: TextStyle(
                      fontSize: web ? 18 : 14,
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: web ? 4 : 3,
                    crossAxisSpacing: web ? 20 : 15,
                    mainAxisSpacing: web ? 20 : 15,
                    childAspectRatio: web ? 0.9 : 0.78,
                  ),
                  itemCount: studentprofile.length,
                  itemBuilder: (context, index) {
                    final studentProfile = studentprofile[index];
                    final cardColor = cardColors[index % cardColors.length];
                    final borderColor = HSLColor.fromColor(cardColor)
                        .withLightness(0.95)
                        .toColor();

                    return GestureDetector(
                      onTap: studentProfile.active == 1
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentProfileScreen(
                                    name: studentProfile.name,
                                    phone: studentProfile.phone,
                                    subject: studentProfile.subject,
                                    image: studentProfile.image,
                                    userID: studentProfile.userID,
                                    address: studentProfile.address,
                                    fatherName: studentProfile.dob,
                                    school: studentProfile.school,
                                    studentClass: studentProfile.studentClass,
                                  ),
                                ),
                              );
                            }
                          : () {
                              showCustomToast(context, 'Account Inactive');
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(25),
                          gradient: SweepGradient(
                            colors: [
                              cardColor,
                              cardColor.withOpacity(0.9),
                              cardColor.withOpacity(0.8),
                              Colors.white54.withOpacity(0.1),
                              cardColor,
                              cardColor
                            ],
                            center: Alignment.topRight,
                            startAngle: 0,
                            endAngle: 6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(4, 4),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(-4, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.0),
                                child: Image.network(
                                  studentProfile.image,
                                  width: web ? 100 : 65,
                                  height: web ? 100 : 65,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                studentProfile.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: web ? 16 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, Color color, String imagePath,
      String title, VoidCallback onTap, bool web) {
    final imageSize = imageSizes[imagePath] ?? {'width': 40.0, 'height': 40.0};
    final scaleFactor = web ? 1.3 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          gradient: SweepGradient(
            colors: [
              color,
              color.withOpacity(0.9),
              color.withOpacity(0.8),
              Colors.white54.withOpacity(0.1),
              color,
              color
            ],
            center: Alignment.topRight,
            startAngle: 0,
            endAngle: 6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: imageSize['width']! * scaleFactor,
              height: imageSize['height']! * scaleFactor,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: web ? 16 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
