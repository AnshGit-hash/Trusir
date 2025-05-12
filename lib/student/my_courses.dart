// my_courses.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trusir/student/course.dart';
import 'package:trusir/student/special_courses.dart';
import 'package:trusir/student/teacher_profile_page.dart';

class Mycourses extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final List<Course> specialCourses;

  const Mycourses({
    super.key,
    required this.courses,
    required this.specialCourses,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return SingleChildScrollView(
      child: Column(
        children: [
          if (courses.isEmpty)
            const Center(
                child:
                    Text('No Courses', style: TextStyle(fontFamily: "Poppins")))
          else if (isWeb)
            _buildWebGrid()
          else
            _buildMobileList(),
          SpecialCourses(courses: specialCourses),
        ],
      ),
    );
  }

  Widget _buildWebGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 560,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) => MyCourseCard(course: courses[index]),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: courses.length,
      itemBuilder: (context, index) => MyCourseCard(course: courses[index]),
    );
  }
}

class MyCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;

  const MyCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final isActive = course['active'] == 1;
    final discount = 100 -
        (int.parse(course['new_amount']) / int.parse(course['amount']) * 100);
    final formattedDiscount = discount.toStringAsFixed(2);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isWeb ? 30 : 16,
        vertical: isWeb ? 15 : 8,
      ),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 30 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourseImage(isWeb, isActive),
            const SizedBox(height: 12),
            Text(
              course['name'],
              style: TextStyle(
                fontSize: isWeb ? 21 : 18,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              course['subject'],
              style: TextStyle(
                fontSize: isWeb ? 18 : 14,
                fontFamily: 'Poppins',
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 5),
            _buildPriceRow(formattedDiscount, isActive),
            const SizedBox(height: 10),
            _buildActionButton(context, isWeb, isActive),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseImage(bool isWeb, bool isActive) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: course['image'],
            width: double.infinity,
            height: isWeb ? 300 : 180,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              height: isWeb ? 300 : 180,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Center(
              child: Icon(
                Icons.error,
                size: 40,
                color: isActive ? Colors.red : Colors.grey,
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.pink : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Best Seller',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isWeb ? 18 : 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String formattedDiscount, bool isActive) {
    return Row(
      children: [
        Text(
          '₹${course['new_amount']}',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.deepPurple : Colors.black,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '₹${course['amount']}',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.grey,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '$formattedDiscount% OFF',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: isActive ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, bool isWeb, bool isActive) {
    return Center(
      child: SizedBox(
        width: isWeb ? 200 : 300,
        height: isWeb ? 40 : null,
        child: ElevatedButton(
          onPressed: isActive
              ? () => _handleKnowMore(context)
              : () => _showInactiveToast(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.blueAccent : Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Know More',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  void _handleKnowMore(BuildContext context) {
    if (course['teacherID'] == 'N/A') {
      _showNoTeacherToast(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherProfilePage(userID: course['teacherID']),
        ),
      );
    }
  }

  void _showInactiveToast(BuildContext context) {
    // Implement toast for inactive course
  }

  void _showNoTeacherToast(BuildContext context) {
    // Implement toast for no teacher assigned
  }
}
