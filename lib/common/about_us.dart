import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: Image.asset('assets/back_button.png', height: 50),
              ),
              const SizedBox(width: 20),
              const Text(
                'About Us',
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
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Our Story Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              color: Colors.white,
              child: Column(
                children: [
                  const Text(
                    'Our Story',
                    style: TextStyle(
                      color: Color(0xFF48116A),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 4,
                    color: const Color(0xFFfdb200),
                    margin: const EdgeInsets.only(top: 15, bottom: 40),
                  ),
                  const Text(
                    'Founded in 2018, TrusiR Home Tutors began with a simple mission: to provide quality education tailored to each student\'s unique needs and learning style.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Our founder, a passionate educator with over 15 years of teaching experience, recognized that many students were struggling within traditional classroom settings. She envisioned a tutoring service that would bridge educational gaps while nurturing students\' confidence and love for learning.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'What started as a small team of dedicated tutors has now grown into a network of over 200 qualified educators serving thousands of students across the country. Despite our growth, we remain committed to our foundational values of personalization, excellence, and genuine care for each student\'s success.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            // Our Mission Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
              color: const Color(0xFFf5f5f5),
              child: Column(
                children: [
                  const Text(
                    'Our Mission',
                    style: TextStyle(
                      color: Color(0xFF48116A),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 4,
                    color: const Color(0xFFfdb200),
                    margin: const EdgeInsets.only(top: 15, bottom: 40),
                  ),
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          spreadRadius: 0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'At TrusiR Home Tutors, our mission is to:',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '• Provide personalized educational support that addresses each student\'s unique learning needs',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '• Foster academic confidence and independence through targeted skill development',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '• Create a positive learning environment where students feel comfortable asking questions and making mistakes',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '• Collaborate with parents and schools to ensure a comprehensive approach to education',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '• Make quality education accessible to students from diverse backgrounds and with various learning styles',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'We believe that with the right guidance, every student can overcome challenges and achieve academic success.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Our Values Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
              color: const Color(0xFFf5f5f5),
              child: Column(
                children: [
                  const Text(
                    'Our Core Values',
                    style: TextStyle(
                      color: Color(0xFF48116A),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 4,
                    color: const Color(0xFFfdb200),
                    margin: const EdgeInsets.only(top: 15, bottom: 40),
                  ),
                  const Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      ValueCard(
                        icon: 'P',
                        title: 'Personalization',
                        description:
                            'We tailor our teaching methods to match each student\'s unique learning style, pace, and needs, ensuring maximum comprehension and retention.',
                      ),
                      ValueCard(
                        icon: 'E',
                        title: 'Excellence',
                        description:
                            'We maintain the highest standards of educational quality through rigorous tutor selection, ongoing training, and evidence-based teaching methods.',
                      ),
                      ValueCard(
                        icon: 'C',
                        title: 'Compassion',
                        description:
                            'We approach education with empathy, understanding that learning challenges can affect confidence, and we strive to create a supportive environment.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ValueCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const ValueCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF48116A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String number;
  final String label;

  const StatItem({
    super.key,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Color(0xFFfdb200),
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
