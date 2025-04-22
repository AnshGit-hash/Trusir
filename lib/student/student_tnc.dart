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
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset('assets/back_button.png', height: 50)),
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
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Please read the following",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Trusir Terms & Conditions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
            SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Service Scope\n'
                      '• Trusir provides home tuition services by connecting students/parents with verified home tutors.\n'
                      '• The tutoring is conducted offline at the student’s home or a mutually agreed location.\n\n'
                      '2. Registration\n'
                      '• Parents or legal guardians must register students under the correct age group.\n'
                      '• Accurate information must be provided during registration, including address, contact details, and academic requirements.\n\n'
                      '3. Tutor Assignment\n'
                      '• Tutors are assigned based on subject requirements, location, and availability.\n'
                      '• Trusir reserves the right to change the tutor if necessary.\n\n'
                      '4. Fees & Payments\n'
                      '• Fees must be paid in advance as per the agreed schedule.\n'
                      '• Refunds are only issued in exceptional cases, subject to TruSir’s discretion.\n'
                      '• Any cancellation must be informed at least 24 hours in advance to avoid charges.\n\n'
                      '5. Code of Conduct\n'
                      '• Students/Parents must ensure a safe, respectful, and non-disruptive environment for tutors.\n'
                      '• Any kind of misconduct, harassment, or inappropriate behavior may lead to termination of services.\n\n'
                      '6. Attendance & Timings\n'
                      '• Punctuality is expected from both sides.\n'
                      '• Missed classes without prior notice will not be rescheduled or refunded.\n\n'
                      '7. Liability\n'
                      '• Trusir verifies tutors to the best of its ability but is not liable for any personal loss, injury, or damage caused during tuition.\n'
                      '• Parents are responsible for the safety and supervision of students at the tuition location.\n\n'
                      '8. Privacy\n'
                      '• Personal information is collected solely for service delivery and is not shared with third parties without consent.\n\n'
                      '9. Changes to Terms\n'
                      '• Trusir reserves the right to update these terms at any time. Users will be notified of major changes.\n\n'
                      '10. Course Renewal Policy\n'
                      '• The monthly tuition fee must be renewed between the 1st and 5th of every month.\n'
                      '• If the payment is not received within this period, the assigned tutor will not continue classes at the student’s location until the renewal is completed.\n'
                      '• TruSir holds the right to reassign the tutor or cancel the service if repeated delays in payment occur.\n\n'
                      '11. Jurisdiction\n'
                      '• All disputes arising from the use of our services shall be subject to the exclusive jurisdiction of the courts at Motihari, Bihar.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
