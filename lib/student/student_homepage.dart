import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/student/student_registration.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentHomepage extends StatefulWidget {
  final bool enableReg;
  final bool enablephone;
  const StudentHomepage(
      {super.key, required this.enablephone, required this.enableReg});

  @override
  State<StudentHomepage> createState() => _StudentHomepageState();
}

class _StudentHomepageState extends State<StudentHomepage> {
  @override
  void initState() {
    super.initState();
    fetchProfileData();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.grey[50],
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> openDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  String name = '';

  Future<void> fetchProfileData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name')!;
    });
  }

  Future<void> _launchWhatsApp(String phoneNumber, String message) async {
    final Uri whatsappUri = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      final bool launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      print("Error launching WhatsApp: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: isWeb
                ? EdgeInsets.only(
                    left: 50, right: 30.0, bottom: widget.enableReg ? 100 : 0)
                : EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 20.0,
                    bottom: widget.enableReg ? 100 : 0,
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: widget.enableReg ? 40 : 0),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trusir.com',
                      style: TextStyle(
                        color: Color(0xFF48116A),
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Welcome text
                widget.enableReg
                    ? const Text(
                        'Welcome To Trusir',
                        style: TextStyle(
                          fontSize: 35,
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      )
                    : Text(
                        'Hello, $name',
                        style: const TextStyle(
                          fontSize: 30,
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                const Divider(
                    color: Colors.black, thickness: 3, endIndent: 230),
                const SizedBox(height: 10),
                const Text(
                  'Trusir is a registered and trusted Indian company that offers Home to Home tuition service. We have a clear vision of helping students achieve their academic goals through one-to-one teaching.',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.6,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF001241),
                  ),
                ),
                const SizedBox(height: 24),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Image.asset(
                    'assets/student_homepage_scroll.png', // or use Image.network / Image.memory if needed
                    height: 300,
                    // Optional: match image height
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),

                // Our Services title
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Our Services',
                    style: TextStyle(
                      fontSize: isWeb ? 28 : 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00081D),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Offline Payment Button with descriptive text
                Image.asset(
                  // height: isWeb ? 2000 : null,
                  'assets/student_homepage.png',
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.fitWidth,
                ),

                // Additional text sections
                const Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: 30.0,
                          left: 6,
                          right: 6,
                        ),
                        child: Text(
                          'Get the Best Tutor for your child',
                          style: TextStyle(
                            fontSize: 22,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF00081D),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Padding(
                        padding: EdgeInsets.only(
                          top: 10.0,
                          left: 6,
                          right: 6,
                        ),
                        child: Text(
                          'Get the best learning support for your child',
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.6,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFBCBCBC),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.only(
                          top: 0,
                          left: 6,
                          right: 6,
                        ),
                        child: Text(
                          'For all your learning support needs such as homework, test, school project and examinations; we are here to give you the best support.',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            height: 1.6,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.only(
                          top: 10,
                          left: 6,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'The best tutors are here',
                            style: TextStyle(
                              fontSize: 20,
                              height: 1.6,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFBCBCBC),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: 10.0,
                          left: 6,
                          right: 6,
                        ),
                        child: Text(
                          'Our tutors are seasoned professionals, screened and given relevant training on a monthly basis to deliver the excellent results you desire.',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            height: 1.6,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Row of two images
                Column(
                  children: [
                    Center(
                      child: Image.asset(
                        height: isWeb ? 200 : null,
                        'assets/t1@3x.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: Image.asset(
                        height: isWeb ? 220 : null,
                        'assets/t2.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                widget.enableReg
                    ? const SizedBox()
                    : const Text(
                        'We are Available in Bihar',
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.6,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                widget.enableReg
                    ? const SizedBox()
                    : const SizedBox(height: 10),
                widget.enableReg
                    ? const SizedBox()
                    : Image.asset('assets/homepage_image.jpg'),
                widget.enableReg
                    ? const SizedBox()
                    : const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Explore City',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF2B395F),
                      height: 1.6,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Subjects Buttons
                Wrap(
                  spacing: 5,
                  runSpacing: 6,
                  children: [
                    'Motihari',
                  ].map((subject) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.purple),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subject,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                widget.enableReg
                    ? const SizedBox()
                    : Image.asset('assets/bihar_map_chart.png'),
                SizedBox(height: widget.enableReg ? 0 : 30),

                // Explore our offerings text
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Explore our offerings',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF2B395F),
                      height: 1.6,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Subjects Buttons
                Wrap(
                  spacing: 5,
                  runSpacing: 6,
                  children: [
                    'Nursery',
                    'LKG',
                    'UKG',
                    'Class 1',
                    'Class 2',
                    'Class 3',
                    'Class 4',
                    'Class 5',
                    'Class 6',
                    'Class 7',
                    'Class 8',
                    'Class 9',
                    'Class 10',
                  ].map((subject) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.purple),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subject,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Explore Boards',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF2B395F),
                      height: 1.6,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Subjects Buttons
                Wrap(
                  spacing: 5,
                  runSpacing: 6,
                  children: [
                    'Bihar School Examination Board',
                    'Central Board of Secondary Education',
                    'Indian Certificate of Secondary Education',
                  ].map((subject) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.purple),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subject,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),

                // Explore Subjects title
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Explore Subjects',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2B395F),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 5,
                  runSpacing: 6,
                  children: [
                    'Hindi',
                    'English',
                    'Maths',
                    'Science: Physics, Chemistry, Biology',
                    'Social Science: History, Geography, Political Science, Economics'
                  ].map((subject) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.purple),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subject,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Fixed Registration Button at bottom
          widget.enableReg
              ? Positioned(
                  left: 0,
                  right: 0,
                  bottom: 5,
                  child: _buildRegistrationButton(context),
                )
              : const SizedBox(),
          Positioned(
            right: 13,
            top: MediaQuery.of(context).size.height * 0.4 - 0,
            child: SizedBox(
              height: isWeb ? 80 : 50,
              width: isWeb ? 80 : 50,
              child: FloatingActionButton(
                heroTag: 'whatsappButton',
                onPressed: () {
                  _launchWhatsApp('918582040204', 'Hello');
                },
                child: Image.asset(
                  'assets/whatsapp@3x.png',
                ),
              ),
            ),
          ),
          Positioned(
            right: 13,
            top: isWeb
                ? MediaQuery.of(context).size.height * 0.55 - 0
                : MediaQuery.of(context).size.height * 0.48 - 0,
            child: SizedBox(
              height: isWeb ? 80 : 50,
              width: isWeb ? 80 : 50,
              child: FloatingActionButton(
                heroTag: 'callButton',
                onPressed: () {
                  openDialer('8582040204');
                },
                child: Image.asset(
                  'assets/call.png',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationButton(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 600;
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentRegistrationPage(),
            ),
          );
        },
        child: Image.asset(
          'assets/registeration.png',
          width: isWeb ? 380 : 280,
          height: isWeb ? 80 : 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class ContactInfoRow extends StatelessWidget {
  final String imagePath;
  final String info;

  const ContactInfoRow({
    super.key,
    required this.imagePath,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          imagePath,
          height: 60,
          width: 60,
        ),
        const SizedBox(width: 10),
        Text(
          info,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
