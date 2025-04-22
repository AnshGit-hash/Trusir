import 'package:flutter/material.dart';

class TrusirTermsWidget extends StatelessWidget {
  const TrusirTermsWidget({super.key});

  Text buildHeading(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      );

  Text buildSubheading(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      );

  Text buildText(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
      );

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeading('1. About Trusir'),
            buildText(
                'Trusir is a platform that connects students (from kids to teenagers) with qualified tutors for offline, in-person home tuition in subjects like Hindi, English, Math, Science, and Social Science. Tutors are independent service providers, not employees of Trusir.'),
            const SizedBox(height: 16),
            buildHeading('2. Eligibility & Registration'),
            buildText(
                '• You must be at least 18 years old to register as a tutor.'),
            buildText(
                '• You must provide accurate, complete, and verifiable information including qualifications, ID proof, and address.'),
            buildText(
                '• Trusir reserves the right to accept or reject tutor registrations at its sole discretion.'),
            const SizedBox(height: 16),
            buildHeading('3. Role & Responsibilities of Tutors'),
            buildText(
                '• Provide quality offline tutoring sessions at the student’s location as per the agreed schedule.'),
            buildText(
                '• Maintain a professional, respectful, and safe teaching environment.'),
            buildText(
                '• Inform Trusir and the student/parent in advance if a session needs to be rescheduled.'),
            buildText(
                '• Do not share personal contact details unnecessarily or request direct payments from parents/students.'),
            const SizedBox(height: 16),
            buildHeading('4. Prohibited Conduct: Direct Dealings'),
            buildText(
                '• Strictly prohibited: After being introduced to a student/parent through Trusir, you must not work with them independently, bypassing Trusir, for any future sessions.'),
            buildText(
                '• Attempting to arrange tuition directly with a student or parent introduced through Trusir will result in immediate blacklisting and removal from the platform, and possible legal action.'),
            buildText(
                '• This restriction applies during your time on Trusir and for 12 months after your last session with that student.'),
            const SizedBox(height: 16),
            buildHeading('5. Payments'),
            buildText(
                '• All payments for sessions must be handled through Trusir.'),
            buildText(
                '• You will receive payment after deduction of Trusir’s service fee/commission.'),
            buildText(
                '• Delays caused by incomplete attendance updates or policy violations may result in withheld payments.'),
            const SizedBox(height: 16),
            buildHeading('6. Code of Conduct'),
            buildText(
                '• Tutors must behave professionally and respectfully with students and parents.'),
            buildText(
                '• Any form of harassment, misconduct, or unprofessional behavior may lead to permanent suspension and reporting to relevant authorities.'),
            buildText(
                '• You must not promote any external services, platforms, or personal business while working through Trusir.'),
            const SizedBox(height: 16),
            buildHeading('7. Background & Verification'),
            buildText(
                '• Trusir may conduct background checks for safety and quality purposes.'),
            buildText(
                '• Falsifying documents or information will lead to immediate termination and possible legal action.'),
            const SizedBox(height: 16),
            buildHeading('8. Termination of Association'),
            buildText(
                '• Trusir reserves the right to suspend or remove any tutor who violates these Terms, receives consistent negative feedback, or engages in unethical behavior.'),
            buildText(
                '• Tutors can deactivate their profile by submitting a written request to support@trusir.com.'),
            const SizedBox(height: 16),
            buildHeading('9. Limitation of Liability'),
            buildText(
                '• Trusir is not responsible for any injury, loss, or dispute arising from your sessions with students.'),
            buildText(
                '• You are responsible for your conduct, safety, and interactions during offline sessions.'),
            const SizedBox(height: 16),
            buildHeading('10. Modification of Terms'),
            buildText(
                '• Trusir reserves the right to modify these Terms at any time.'),
            buildText(
                '• Continued use of the platform after updates implies acceptance of the revised Terms.'),
            const SizedBox(height: 16),
            buildHeading('11. Contact Us'),
            buildText('For questions or support:'),
            buildText('Email: support@trusir.com'),
            buildText('Website: www.trusir.com'),
            buildText(
                'App Support: Available through the Trusir app (Android & iOS)'),
            const SizedBox(height: 16),
            buildHeading('12. Jurisdiction'),
            buildText(
                '• All disputes arising from the use of our services shall be subject to the exclusive jurisdiction of the courts at Motihari, Bihar.'),
          ],
        ),
      ),
    );
  }
}
