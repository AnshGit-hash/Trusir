import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:trusir/common/api.dart';

class TeacherProfilePage extends StatefulWidget {
  final String userID;
  const TeacherProfilePage({super.key, required this.userID});

  @override
  MyProfileScreenState createState() => MyProfileScreenState();
}

class MyProfileScreenState extends State<TeacherProfilePage> {
  String name = '';
  String age = '';
  String dob = '';
  String gender = '';
  String address = '';
  String graduation = '';
  String experience = '';
  String subjects = '';
  String language = '';
  String phoneNumber = '';
  String profilePhoto = '';
  String fatherName = '';

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  @override
  void dispose() {
    // Reset status bar to default when leaving the page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.grey[50],
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  int calculateAge(String dob) {
    // Parse the DOB string to a DateTime object
    DateTime dateOfBirth = DateTime.parse(dob);
    DateTime today = DateTime.now();

    // Calculate the age
    int age = today.year - dateOfBirth.year;

    // Check if the birthday has not yet occurred this year
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }

    return age;
  }

  Future<void> fetchProfileData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get-user/${widget.userID}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          name = data['name'] ?? 'N/A';
          dob = data['DOB'] ?? '2001-01-01';
          age = calculateAge(dob).toString();
          gender = data['gender'] ?? 'N/A';
          address = data['address'] ?? 'N/A';
          graduation = data['qualification'] ?? 'N/A';
          experience = data['experience'] ?? 'N/A';
          fatherName = data['father_name'] ?? 'N/A';
          subjects = data['subject'] ?? 'N/A';
          language = data['medium'] ?? 'N/A';
          phoneNumber = data['phone'] ?? 'N/A';
          profilePhoto = data['profile'] ??
              'https://via.placeholder.com/150'; // Fallback image URL
        });
        print('Data fetched Successfully');
      } else {
        throw Exception('Failed to load profile data');
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const rowColors = [
      Color.fromARGB(255, 255, 199, 221),
      Color.fromARGB(255, 216, 185, 255),
      Color.fromARGB(255, 199, 255, 215),
      Color.fromARGB(255, 199, 236, 255),
      Color.fromARGB(255, 255, 185, 185),
    ];
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 70,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: 428,
              height: 180,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(profilePhoto),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF48116A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            buildInfoRow('assets/men@4x.png', 'Father Name', 63, fatherName,
                rowColors[0]),
            const SizedBox(height: 10),
            buildInfoRow('assets/degree@2x.png', 'Graduation', 63, graduation,
                rowColors[1]),
            const SizedBox(height: 10),
            buildInfoRow('assets/medal@2x.png', 'Experience', 63, experience,
                rowColors[2]),
            const SizedBox(height: 10),
            buildInfoRow('assets/phone@2x.png', 'Phone Number', 63,
                '+91-$phoneNumber', rowColors[3]),
            const SizedBox(height: 10),
            buildInfoRow('assets/location@2x.png', 'Address', null, address,
                rowColors[4]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String iconPath, String title, double? containerHeight,
      String value, Color backgroundColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 55,
            height: 63,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Image.asset(
                iconPath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Text container
          Flexible(
            child: Container(
              height: 60,
              width: 306,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 20, top: 10, bottom: 10, right: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRect(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        value.isNotEmpty ? value : 'Loading...',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: "Poppins",
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
