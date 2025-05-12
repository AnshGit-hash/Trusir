import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/student/attendance.dart';
import 'package:trusir/student/course.dart';
import 'package:trusir/student/gk_page.dart';
import 'package:trusir/student/profilepopup.dart';
import 'package:trusir/common/test_series.dart';
import 'package:trusir/student/fee_payment.dart';
import 'package:trusir/student/my_profile.dart';
import 'package:trusir/student/notice.dart';
import 'package:trusir/student/parents_doubt.dart';
import 'package:trusir/student/progress_report.dart';
import 'package:trusir/student/setting.dart';
import 'package:trusir/student/student_doubt.dart';
import 'package:trusir/student/teacher_profile.dart';
import 'package:trusir/student/video_knowledge.dart';
import 'package:trusir/common/wanna_logout.dart';

class Studentfacilities extends StatefulWidget {
  const Studentfacilities({super.key});

  @override
  State<Studentfacilities> createState() => _StudentfacilitiesState();
}

class _StudentfacilitiesState extends State<Studentfacilities> {
  String name = '';
  String profile = '';
  String area = '';
  String city = '';
  String phone = '';
  String userID = '';
  bool checking = false;
  String checkTitle = '';
  List<MyCourseModel> _courseDetails = [];
  List<Teacher> teachers = [];

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
    'assets/video knowledge.png': {'width': 85, 'height': 55},
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await fetchProfileData();
    await check();
  }

  Future<void> check() async {
    await Future.wait([fetchCourses(), fetchTeachers()]);
    setState(() {
      checking = _courseDetails.isEmpty || teachers.isEmpty;
      if (_courseDetails.isEmpty) {
        checkTitle = 'Please enroll in a course First';
      } else if (teachers.isEmpty) {
        checkTitle = 'We will assign you a teacher shortly';
      }
    });
  }

  Future<List<MyCourseModel>> fetchCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');
    final response = await http.get(Uri.parse('$baseUrl/get-courses/$userID'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _courseDetails =
          data.map((json) => MyCourseModel.fromJson(json)).toList();
      return _courseDetails;
    } else {
      throw Exception('Failed to fetch courses');
    }
  }

  Future<void> fetchTeachers() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');
    final response = await http.get(Uri.parse('$baseUrl/teacher/$userID'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      teachers = data.map((json) => Teacher.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load teachers');
    }
  }

  Future<void> fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userID') ?? '';
      name = prefs.getString('name') ?? '';
      profile = prefs.getString('profile') ?? '';
      area = prefs.getString('area') ?? '';
      city = prefs.getString('city') ?? '';
      phone = prefs.getString('phone_number') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final tileWidth = isWeb ? 116 * 1.2 : 116;
    final tileHeight = isWeb ? 140 * 1.2 : 140;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Student Facilities',
          style: TextStyle(
            color: Color(0xFF48116A),
            fontSize: 22,
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
                  builder: (context) => WanaLogout(profile: profile),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Image.asset(
                'assets/logout@3x.png',
                width: 103,
                height: 24,
              ),
            ),
          ),
        ],
        toolbarHeight: 60,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = isWeb
              ? 700
              : constraints.maxWidth > 388
                  ? 388
                  : constraints.maxWidth - 40;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: isWeb ? 50 : 20.0,
              right: isWeb ? 50 : 20.0,
              top: 10.0,
              bottom: 20.0, // Added bottom padding for scroll
            ),
            child: Column(
              children: [
                _buildProfileCard(isWeb, double.parse('$contentWidth')),
                const SizedBox(height: 15),
                _buildGridTiles(isWeb, double.parse('$tileWidth'),
                    double.parse('$tileHeight')),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(bool isWeb, double width) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, _, __) => const ProfilePopup(),
          ),
        );
      },
      child: Container(
        width: width,
        height: isWeb ? 150 : null,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF48116A),
              Color(0xFFC22054),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC22054).withOpacity(0.3),
              spreadRadius: 3,
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              isWeb ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    left: isWeb ? 60 : 20.0, top: 12, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isWeb
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWeb ? 25 : 22,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Row(
                        children: [
                          Text(
                            '$area, ',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWeb ? 19 : 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            city,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWeb ? 19 : 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        phone,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: isWeb ? 16 : 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: isWeb ? 50 : 12.0),
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
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    profile,
                    width: isWeb ? 100 : 75,
                    height: isWeb ? 100 : 75,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 50,
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

  Widget _buildGridTiles(bool isWeb, double tileWidth, double tileHeight) {
    final tiles = [
      _TileData(
        color: const Color.fromARGB(255, 170, 224, 249),
        image: 'assets/myprofile.png',
        title: 'My Profile',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyProfileScreen()),
        ),
      ),
      _TileData(
        color: const Color.fromARGB(255, 248, 169, 227),
        image: 'assets/teacherprofile.png',
        title: 'Teacher Profile',
        onTap: checking
            ? () => showCustomToast(context, checkTitle)
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TeacherProfileScreen()),
                ),
      ),
      _TileData(
        color: const Color.fromARGB(255, 109, 216, 249),
        image: 'assets/attendance.png',
        title: 'Attendance',
        onTap: checking
            ? () => showCustomToast(context, checkTitle)
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AttendancePage(userID: userID)),
                ),
      ),
      _TileData(
        color: const Color.fromARGB(255, 222, 151, 255),
        image: 'assets/money.png',
        title: 'Fee Payment',
        onTap: checking
            ? () => showCustomToast(context, checkTitle)
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FeePaymentScreen()),
                ),
      ),
      _TileData(
        color: const Color.fromARGB(255, 188, 180, 255),
        image: 'assets/pencil and ruller.png',
        title: 'Test Series',
        onTap: checking
            ? () => showCustomToast(context, checkTitle)
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TestSeriesScreen(userID: userID)),
                ),
      ),
      _TileData(
        color: const Color.fromARGB(255, 235, 177, 236),
        image: 'assets/medal.png',
        title: 'Progress Report',
        onTap: checking
            ? () => showCustomToast(context, checkTitle)
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProgressReportScreen()),
                ),
      ),
      _TileData(
        color: const Color.fromARGB(255, 151, 177, 255),
        image: 'assets/qna.png',
        title: 'Student Doubt',
        onTap: checking
            ? () => showCustomToast(context, checkTitle)
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const StudentDoubtScreen()),
                ),
      ),
      _TileData(
        color: const Color(0xFFB3E5FC),
        image: 'assets/sir.png',
        title: 'Parents Doubt',
        onTap: checking
            ? () => showCustomToast(context, checkTitle)
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ParentsDoubtScreen()),
                ),
      ),
      _TileData(
        color: const Color.fromARGB(255, 255, 170, 157),
        image: 'assets/knowledge.png',
        title: 'General Knowledge',
        onTap: checking
            ? () => showCustomToast(context, checkTitle)
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GKPage()),
                ),
      ),
      _TileData(
        color: const Color.fromARGB(255, 182, 202, 255),
        image: 'assets/notice.png',
        title: 'Notice',
        onTap: checking
            ? () => showCustomToast(context, checkTitle)
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NoticeScreen()),
                ),
      ),
      _TileData(
        color: const Color.fromARGB(189, 244, 133, 232),
        image: 'assets/setting.png',
        title: 'Settings',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsScreen(
              checkTitle: checkTitle,
              checking: checking,
            ),
          ),
        ),
      ),
      _TileData(
        color: const Color.fromARGB(255, 250, 217, 108),
        image: 'assets/video knowledge.png',
        title: 'Video Knowledge',
        onTap: checking
            ? () => showCustomToast(context, checkTitle)
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VideoKnowledge()),
                ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWeb ? 5 : 3,
        crossAxisSpacing: isWeb ? 30 : 17,
        mainAxisSpacing: isWeb ? 30 : 10,
        childAspectRatio:
            isWeb ? tileWidth / tileHeight * 1.5 : tileWidth / tileHeight,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) => _buildTile(
        context,
        tiles[index].color,
        tiles[index].image,
        tiles[index].title,
        tileWidth,
        tileHeight,
        tiles[index].onTap,
        isWeb,
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    Color color,
    String imagePath,
    String title,
    double tileWidth,
    double tileHeight,
    VoidCallback onTap,
    bool isWeb,
  ) {
    final imageSize = imageSizes[imagePath] ??
        {'width': isWeb ? 180 : 40.0, 'height': isWeb ? 180 : 40.0};
    final scaleFactor = isWeb
        ? (MediaQuery.of(context).size.width < 1200 ? 1.8 : 1.7)
        : (MediaQuery.of(context).size.width < 360 ? 0.7 : 1.0);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: tileWidth,
        height: isWeb ? tileHeight * 0.4 : tileHeight,
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
              color,
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
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isWeb ? 13 * (scaleFactor * 0.6) : 12 * scaleFactor,
                  fontFamily: 'Poppins',
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

class _TileData {
  final Color color;
  final String image;
  final String title;
  final VoidCallback onTap;

  _TileData({
    required this.color,
    required this.image,
    required this.title,
    required this.onTap,
  });
}
