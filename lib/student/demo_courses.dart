// demo_courses.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trusir/student/teacher_profile_page.dart';

class Democourses extends StatelessWidget {
  final List<Map<String, dynamic>> courses;

  const Democourses({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return courses.isEmpty
        ? const Center(
            child: Text('No Courses', style: TextStyle(fontFamily: "Poppins")))
        : isWeb
            ? _buildWebGrid()
            : _buildMobileList();
  }

  Widget _buildWebGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 560,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) => DemoCourseCard(course: courses[index]),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: courses.length,
      itemBuilder: (context, index) => DemoCourseCard(course: courses[index]),
    );
  }
}

class DemoCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;

  const DemoCourseCard({super.key, required this.course});

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
            _buildActionButtons(context, isWeb, isActive),
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

  Widget _buildActionButtons(BuildContext context, bool isWeb, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBuyNowButton(context, isWeb, isActive),
        const SizedBox(width: 10),
        _buildKnowMoreButton(context, isWeb, isActive),
      ],
    );
  }

  Widget _buildBuyNowButton(BuildContext context, bool isWeb, bool isActive) {
    return SizedBox(
      width: isWeb ? 200 : 142,
      height: isWeb ? 40 : null,
      child: ElevatedButton(
        onPressed: isActive
            ? () => _showPaymentDialog(context)
            : () => _showInactiveToast(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.deepPurple : Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Buy Now',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildKnowMoreButton(BuildContext context, bool isWeb, bool isActive) {
    return SizedBox(
      width: isWeb ? 200 : 142,
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
    );
  }

  void _showPaymentDialog(BuildContext context) {
    // Implement payment dialog
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
