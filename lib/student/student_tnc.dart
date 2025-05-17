import 'package:flutter/material.dart';

class TrusirTermsPage extends StatelessWidget {
  const TrusirTermsPage({super.key});

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
                onTap: () => Navigator.pop(context),
                child: Image.asset('assets/back_button.png', height: 50),
              ),
              const SizedBox(width: 20),
              const Text(
                'Terms & Conditions',
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: "1. Service Scope",
                points: [
                  "Trusir provides home tuition services by connecting students/parents with verified home tutors.",
                  "The tutoring is conducted offline at the student's home or a mutually agreed location.",
                ],
              ),
              _buildSection(
                title: "2. Registration",
                points: [
                  "Parents or legal guardians must register students under the correct age group.",
                  "Accurate information must be provided during registration, including address, contact details, and academic requirements.",
                ],
              ),
              _buildSection(
                title: "3. Tutor Assignment",
                points: [
                  "Tutors are assigned based on subject requirements, location, and availability.",
                  "Trusir reserves the right to change the tutor if necessary.",
                ],
              ),
              _buildSection(
                title: "4. Fees & Payments",
                points: [
                  "Fees must be paid in advance as per the agreed schedule.",
                  "Refunds are only issued in exceptional cases, subject to TruSir's discretion.",
                  "Any cancellation must be informed at least 24 hours in advance to avoid charges.",
                ],
              ),
              _buildSection(
                title: "5. Code of Conduct",
                points: [
                  "Students/Parents must ensure a safe, respectful, and non-disruptive environment for tutors.",
                  "Any kind of misconduct, harassment, or inappropriate behavior may lead to termination of services.",
                ],
              ),
              _buildSection(
                title: "6. Attendance & Timings",
                points: [
                  "Punctuality is expected from both sides.",
                  "Missed classes without prior notice will not be rescheduled or refunded.",
                ],
              ),
              _buildSection(
                title: "7. Liability",
                points: [
                  "Trusir verifies tutors to the best of its ability but is not liable for any personal loss, injury, or damage caused during tuition.",
                  "Parents are responsible for the safety and supervision of students at the tuition location.",
                ],
              ),
              _buildSection(
                title: "8. Privacy",
                points: [
                  "Personal information is collected solely for service delivery and is not shared with third parties without consent.",
                ],
              ),
              _buildSection(
                title: "9. Changes to Terms",
                points: [
                  "Trusir reserves the right to update these terms at any time. Users will be notified of major changes.",
                ],
              ),
              _buildSection(
                title: "10. Course Renewal Policy",
                points: [
                  "The monthly tuition fee must be renewed between the 1st and 5th of every month.",
                  "If the payment is not received within this period, the assigned tutor will not continue classes at the student's location until the renewal is completed.",
                  "TruSir holds the right to reassign the tutor or cancel the service if repeated delays in payment occur.",
                ],
              ),
              _buildSection(
                title: "11. Jurisdiction",
                points: [
                  "All disputes arising from the use of our services shall be subject to the exclusive jurisdiction of the courts at Motihari, Bihar.",
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  '© 2025 Trusir. All Rights Reserved.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<String> points}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF48116A),
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          ...points.map((point) => _buildBulletPoint(point)),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3, right: 8),
            child: Icon(
              Icons.circle,
              size: 8,
              color: Color(0xFFFDB200),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
