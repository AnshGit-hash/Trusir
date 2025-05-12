// special_courses.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trusir/student/course.dart';

class SpecialCourses extends StatelessWidget {
  final List<Course> courses;

  const SpecialCourses({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    final isWeb = MediaQuery.of(context).size.width > 600;

    return isWeb ? _buildWebGrid() : _buildMobileList();
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
      itemBuilder: (context, index) =>
          SpecialCourseCard(course: courses[index]),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: courses.length,
      itemBuilder: (context, index) =>
          SpecialCourseCard(course: courses[index]),
    );
  }
}

class SpecialCourseCard extends StatelessWidget {
  final Course course;

  const SpecialCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final discount =
        100 - (int.parse(course.newAmount) / int.parse(course.amount) * 100);
    final formattedDiscount = discount.toStringAsFixed(2);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isWeb ? 30 : 16,
        vertical: isWeb ? 15 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
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
            _buildCourseImage(isWeb),
            const SizedBox(height: 12),
            Text(
              course.name,
              style: TextStyle(
                fontSize: isWeb ? 21 : 18,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              course.subject,
              style: TextStyle(
                fontSize: isWeb ? 18 : 14,
                fontFamily: 'Poppins',
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 5),
            _buildPriceRow(formattedDiscount),
            const SizedBox(height: 10),
            _buildActionButtons(context, isWeb),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseImage(bool isWeb) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: course.image,
            width: double.infinity,
            height: isWeb ? 300 : 180,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              height: isWeb ? 300 : 180,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.error, size: 40, color: Colors.red),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.pink,
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

  Widget _buildPriceRow(String formattedDiscount) {
    return Row(
      children: [
        Text(
          '₹${course.newAmount}',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '₹${course.amount}',
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
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isWeb) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBuyNowButton(context, isWeb),
        const SizedBox(width: 10),
        _buildBookDemoButton(isWeb),
      ],
    );
  }

  Widget _buildBuyNowButton(BuildContext context, bool isWeb) {
    return SizedBox(
      width: isWeb ? 200 : 142,
      height: isWeb ? 40 : null,
      child: ElevatedButton(
        onPressed: () => _showPaymentDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
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

  Widget _buildBookDemoButton(bool isWeb) {
    return SizedBox(
      width: isWeb ? 200 : 142,
      height: isWeb ? 40 : null,
      child: ElevatedButton(
        onPressed: () {}, // Implement book demo functionality
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 225, 143, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Book Demo',
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
}
