import 'package:flutter/material.dart';
import 'package:trusir/common/custom_toast.dart';
// import 'package:trusir/common/delete.dart';
import 'package:trusir/student/course.dart';
// import 'package:trusir/student/main_screen.dart';
import 'package:trusir/student/special_courses.dart';
import 'package:trusir/student/teacher_profile_page.dart';

class Mycourses extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final List<Course> specialCourses;
  const Mycourses(
      {super.key, required this.courses, required this.specialCourses});

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 600;
    return SingleChildScrollView(
      child: Column(
        children: [
          courses.isEmpty
              ? const Center(
                  child: Text(
                  'No Courses',
                  style: TextStyle(
                    fontFamily: "Poppins",
                  ),
                ))
              : isWeb
                  ? GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, mainAxisExtent: 560),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return MyCourseCard(
                          course: course,
                        );
                      },
                    )
                  : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return MyCourseCard(
                          course: course,
                        );
                      },
                    ),
          SpecialCourses(courses: specialCourses)
        ],
      ),
    );
  }
}

class MyCourseCard extends StatefulWidget {
  final Map<String, dynamic> course;

  const MyCourseCard({super.key, required this.course});

  @override
  State<MyCourseCard> createState() => _MyCourseCardState();
}

class _MyCourseCardState extends State<MyCourseCard> {
  bool isWeb = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    isWeb = MediaQuery.of(context).size.width > 600;
    double discount = 100 -
        int.parse(widget.course['new_amount']) /
            int.parse(widget.course['amount']) *
            100;

    String formattedDiscount = discount.toStringAsFixed(2);
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: isWeb ? 30 : 16, vertical: isWeb ? 15 : 8),
      decoration: BoxDecoration(
        color: widget.course['active'] == 1 ? Colors.white : Colors.grey,
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
        padding: EdgeInsets.all(isWeb ? 30 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.course['image'],
                    width: double.infinity,
                    height: isWeb ? 300 : 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.error,
                          size: 40,
                          color: widget.course['active'] == 1
                              ? Colors.red
                              : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.course['active'] == 1
                          ? Colors.pink
                          : Colors.grey,
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
                // Positioned(
                //     top: 0,
                //     right: 0,
                //     child: IconButton(
                //         onPressed: widget.course['active'] == 1
                //             ? () {
                //                 showDialog(
                //                   context: context,
                //                   builder: (BuildContext context) {
                //                     return AlertDialog(
                //                       title: const Text("Confirm Deletion"),
                //                       content: const Text(
                //                           "Are you sure you want to delete?"),
                //                       actions: [
                //                         TextButton(
                //                           onPressed: () => Navigator.pop(
                //                               context), // Dismiss dialog
                //                           child: const Text("Cancel"),
                //                         ),
                //                         TextButton(
                //                           onPressed: () {
                //                             DeleteUtility.deleteItem(
                //                                 'individualSlot',
                //                                 widget.course['slotID']);
                //                             Navigator.pop(context);
                //                             Navigator.pushReplacement(
                //                                 context,
                //                                 MaterialPageRoute(
                //                                     builder: (context) =>
                //                                         const MainScreen(
                //                                             index: 1)));
                //                           }, // Confirm deletion
                //                           child: const Text("OK"),
                //                         ),
                //                       ],
                //                     );
                //                   },
                //                 );
                //               }
                //             : () {
                //                 showCustomToast(context,
                //                         'Course Inactive, Please Contact Admin');
                //               },
                //         icon: Icon(
                //           Icons.close,
                //           color: widget.course['active'] == 1
                //               ? Colors.redAccent
                //               : Colors.grey,
                //         )))
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.course['name'],
              style: TextStyle(
                fontSize: isWeb ? 21 : 18,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.course['subject'],
              style: TextStyle(
                fontSize: isWeb ? 18 : 14,
                fontFamily: 'Poppins',
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  '₹${widget.course['new_amount']}',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: widget.course['active'] == 1
                        ? Colors.deepPurple
                        : Colors.black,
                  ),
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  '₹${widget.course['amount']}', // Placeholder for original price
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.grey,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  '$formattedDiscount% OFF', // Placeholder for original price
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: widget.course['active'] == 1
                        ? Colors.green
                        : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: isWeb ? 200 : 300,
                height: isWeb ? 40 : null,
                child: ElevatedButton(
                  onPressed: widget.course['active'] == 1
                      ? () {
                          widget.course['teacherID'] == 'N/A'
                              ? showCustomToast(
                                  context, 'No Teachers Assigned Yet')
                              : Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => TeacherProfilePage(
                                          userID: widget.course['teacherID'])),
                                );
                        }
                      : () {
                          showCustomToast(
                              context, 'Course Inactive, Please Contact Admin');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.course['active'] == 1
                        ? Colors.blueAccent
                        : Colors.black54,
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
            )
          ],
        ),
      ),
    );
  }
}
