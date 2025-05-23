import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trusir/common/menu.dart';
import 'package:trusir/student/student_enquiry.dart';
import 'package:trusir/teacher/teacher_enquiry.dart';
import 'package:url_launcher/url_launcher.dart';

class EnquiryPage extends StatelessWidget {
  const EnquiryPage({super.key});

  Future<void> openDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 0.0),
          child: Row(
            children: [
              GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset('assets/back_button.png', height: 50)),
              const SizedBox(width: 20),
              const Text(
                'Enquiry',
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
        toolbarHeight: 50,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 16.0, right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Student Enquiry Image
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentEnquiryPage(),
                  ),
                );
              },
              child: Image.asset(
                "assets/studentenquiry.png", // Ensure asset path is correct
                width: 340,
                height: 225,
              ),
            ),

            // Teacher Enquiry Image
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherEnquiryPage(),
                  ),
                );
              },
              child: Image.asset(
                "assets/teacherenquiry.png",
                width: 340,
                height: 225,
              ),
            ),
            TextButton(
              onPressed: () {
                showPopupDialog(context);
              },
              child: const Text(
                'Skip to Registration',
                style: TextStyle(
                  fontSize: 20,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8C4C92),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            kIsWeb ? const Spacer() : const SizedBox(height: 20),
            const Text(
              'Or Enquire On',
              style: TextStyle(
                fontSize: 20,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8C4C92),
                fontFamily: 'Poppins',
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _launchWhatsApp('918582040204', 'Hi');
                      },
                      child: Image.asset(
                        'assets/whatsapp@3x.png',
                        width: 70,
                        height: 70,
                      ),
                    ),
                    const SizedBox(width: 70),

                    // Call Button
                    GestureDetector(
                      onTap: () {
                        openDialer('8582040204');
                      },
                      child: Image.asset(
                        'assets/call.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showPopupDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext context) {
        return const PopupScreen();
      },
    );
  }
}
