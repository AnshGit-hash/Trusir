import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/student/teacher_profile_page.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:trusir/common/api.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  TeacherProfileScreenState createState() => TeacherProfileScreenState();
}

class TeacherProfileScreenState extends State<TeacherProfileScreen> {
  List<Teacher> teachers = [];
  bool isLoading = true;
  bool hasError = false;
  String? studentClass;

  @override
  void initState() {
    super.initState();
    fetchTeachers();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.grey[50],
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  Future<Map<String, List<String>>> fetchTeacherSubjects() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userID = prefs.getString('userID');
    final url = Uri.parse('$baseUrl/get-individual-slots/$userID');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        Map<String, List<String>> teacherSubjects = {};

        for (var item in data) {
          final teacherID = item['teacherID'];
          final subject = item['subject'] ?? 'No Subject';

          if (teacherID != null && subject != null) {
            if (!teacherSubjects.containsKey(teacherID)) {
              teacherSubjects[teacherID] = [];
            }
            if (!teacherSubjects[teacherID]!.contains(subject)) {
              teacherSubjects[teacherID]!.add(subject);
            }
          }
        }
        return teacherSubjects;
      } else {
        throw Exception('Failed to load subjects data');
      }
    } catch (e) {
      throw Exception('Error fetching subjects: $e');
    }
  }

  Future<void> fetchTeachers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userID = prefs.getString('userID');
    studentClass = prefs.getString('class');

    try {
      final subjectsMap = await fetchTeacherSubjects();
      final response = await http.get(Uri.parse('$baseUrl/teacher/$userID'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Teacher> loadedTeachers = [];

        for (var jsonTeacher in data) {
          Teacher teacher = Teacher.fromJson(jsonTeacher);

          if (subjectsMap.containsKey(teacher.id.toString())) {
            teacher = Teacher(
              id: teacher.id,
              name: teacher.name,
              userID: teacher.userID,
              fatherName: teacher.fatherName,
              motherName: teacher.motherName,
              gender: teacher.gender,
              teacherClass: teacher.teacherClass,
              subject: subjectsMap[teacher.id.toString()]!.join(', '),
              dob: teacher.dob,
              phone: teacher.phone,
              role: teacher.role,
              school: teacher.school,
              medium: teacher.medium,
              state: teacher.state,
              city: teacher.city,
              address: teacher.address,
              area: teacher.area,
              pincode: teacher.pincode,
              qualification: teacher.qualification,
              experience: teacher.experience,
              adhaarFront: teacher.adhaarFront,
              adhaarBack: teacher.adhaarBack,
              profile: teacher.profile,
              timeSlot: teacher.timeSlot,
            );
          }
          loadedTeachers.add(teacher);
        }

        setState(() {
          teachers = loadedTeachers;
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      print("Error fetching teacher data: $e");
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF48116A)),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading teacher profiles...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/no_teachers.png', height: 120), // Add your asset
          const SizedBox(height: 20),
          const Text(
            'No Teachers Assigned Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF48116A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your teachers will appear here once assigned',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            'Failed to load teacher data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF48116A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: fetchTeachers,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF48116A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherGrid() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: teachers.length,
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                return GestureDetector(
                  onTap: () =>
                      showPopupDialog(context, teacher.phone, teacher.userID),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Container(
                        width: 180,
                        height: 251,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 98,
                              height: 101,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(teacher.profile),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              teacher.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              teacher.phone,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              teacher.subject,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -5,
                        left: -30,
                        child: Transform.rotate(
                          angle: -0.785398,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 0, left: 0, right: 0),
                            child: Container(
                              width: 150,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                teacher.teacherClass
                                            .split(',')
                                            .where((cls) =>
                                                cls.trim() == studentClass)
                                            .join(', ') ==
                                        ''
                                    ? studentClass!
                                    : teacher.teacherClass
                                        .split(',')
                                        .where(
                                            (cls) => cls.trim() == studentClass)
                                        .join(', '),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 1.0),
          child: Row(
            children: [
              GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset('assets/back_button.png', height: 50)),
              const SizedBox(width: 20),
              const Text(
                'Teacher Profile',
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
      body: isLoading
          ? _buildLoadingState()
          : hasError
              ? _buildErrorState()
              : teachers.isEmpty
                  ? _buildEmptyState()
                  : _buildTeacherGrid(),
    );
  }
}

class PopupScreen extends StatelessWidget {
  final String phone;
  final String userID;
  const PopupScreen({super.key, required this.phone, required this.userID});

  Future<void> openDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openDialer(phone);
                },
                child: const Text(
                  "Call Teacher",
                  style: TextStyle(
                      fontSize: 18, color: Colors.black, fontFamily: 'Poppins'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Button for "I'm a Teacher"
            Container(
              width: 200,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TeacherProfilePage(userID: userID)),
                  );
                },
                child: const Text(
                  "View Profile",
                  style: TextStyle(
                      fontSize: 18, color: Colors.black, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showPopupDialog(BuildContext context, String phone, String userID) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (BuildContext context) {
      return PopupScreen(phone: phone, userID: userID);
    },
  );
}

class Teacher {
  final int id;
  final String name;
  final String userID;
  final String fatherName;
  final String motherName;
  final String gender;
  final String teacherClass;
  final String subject;
  final String dob;
  final String phone;
  final String role;
  final String school;
  final String medium;
  final String state;
  final String city;
  final String address;
  final String area;
  final String pincode;
  final String qualification;
  final String experience;
  final String adhaarFront;
  final String adhaarBack;
  final String profile;
  final String timeSlot;

  Teacher({
    required this.id,
    required this.name,
    required this.userID,
    required this.fatherName,
    required this.motherName,
    required this.gender,
    required this.teacherClass,
    required this.subject,
    required this.dob,
    required this.phone,
    required this.role,
    required this.school,
    required this.medium,
    required this.state,
    required this.city,
    required this.address,
    required this.area,
    required this.pincode,
    required this.qualification,
    required this.experience,
    required this.adhaarFront,
    required this.adhaarBack,
    required this.profile,
    required this.timeSlot,
  });

  // Factory method to parse JSON data
  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      name: json['name'] ?? 'N/A',
      userID: json['userID'] ?? 'N/A',
      fatherName: json['father_name'] ?? 'N/A',
      motherName: json['mother_name'] ?? 'N/A',
      gender: json['gender'] ?? 'N/A',
      teacherClass: json['class'],
      subject: json['subject'] ?? 'N/A',
      dob: json['DOB'] ?? 'N/A',
      phone: json['phone'] ?? 'N/A',
      role: json['role'] ?? 'N/A',
      school: json['school'] ?? 'N/A',
      medium: json['medium'] ?? 'N/A',
      state: json['state'] ?? 'N/A',
      city: json['city'] ?? 'N/A',
      address: json['address'] ?? 'N/A',
      area: json['area'] ?? 'N/A',
      pincode: json['pincode'] ?? 'N/A',
      qualification: json['qualification'] ?? 'N/A',
      experience: json['experience'] ?? 'N/A',
      adhaarFront: json['adhaar_front'] ?? 'N/A',
      adhaarBack: json['adhaar_back'] ?? 'N/A',
      profile: json['profile'] ?? 'N/A',
      timeSlot: json['time_slot'] ?? 'N/A',
    );
  }
}
