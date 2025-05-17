import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/common/image_uploading.dart';
import 'package:trusir/teacher/add_gk.dart';
import 'package:trusir/teacher/teacher_facilities.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class AddGkTeacher extends StatefulWidget {
  final List<StudentProfile> studentprofile;
  const AddGkTeacher({super.key, required this.studentprofile});

  @override
  State<AddGkTeacher> createState() => _AddGkTeacherState();
}

class _AddGkTeacherState extends State<AddGkTeacher> {
  @override
  void dispose() {
    // Reset status bar to default when leaving the page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.grey[50],
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedStudent;
  String? selecteduserID;
  List<String> selectedStudents = [];
  List<String> names = [];
  final GK formData = GK();
  List<StudentProfile> students = [];
  Map<String, String> nameUserMap = {};

  @override
  void initState() {
    super.initState();
    setState(() {
      students = widget.studentprofile;
      extractStudentData(students, names, nameUserMap);
      print(nameUserMap);
    });
  }

  void extractStudentData(List<StudentProfile> students, List<String> names,
      Map<String, String> nameUserIDMap) {
    for (var student in students) {
      names.add(student.name);
      nameUserIDMap[student.name] = student.userID;
    }
  }

  Future<void> handleUploadFromCamera() async {
    final String result =
        await ImageUploadUtils.uploadSingleImageFromCamera(context);

    if (result != 'null') {
      setState(() {
        setState(() {
          formData.photo = result;
        });
      });
      showCustomToast(context, 'Image uploaded successfully!');
    } else {
      showCustomToast(context, 'Image upload failed!');
      setState(() {});
    }
  }

  Future<void> handleUploadFromGallery() async {
    final String result =
        await ImageUploadUtils.uploadSingleImageFromGallery(context);

    if (result != 'null') {
      setState(() {
        setState(() {
          formData.photo = result;
        });
      });
      showCustomToast(context, 'Image uploaded successfully!');
    } else {
      showCustomToast(context, 'Image upload failed!');
    }
  }

  Future<void> submitForm() async {
    formData.title =
        titleController.text.isEmpty ? "No Title" : titleController.text;
    formData.description = descriptionController.text.isEmpty
        ? "No Description"
        : descriptionController.text;

    formData.studclass = 'class';

    if (formData.photo == null || formData.photo!.isEmpty) {
      showCustomToast(context, 'Upload the image');
      return;
    }

    if (selectedStudents.isEmpty) {
      showCustomToast(context, 'Select at least one student');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userID');
    print(userId);
    for (String student in selectedStudents) {
      String? studentUserID = nameUserMap[student];
      print(studentUserID);

      final url = Uri.parse('$baseUrl/api/tecaher-gks/$userId/$studentUserID');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode(formData.toJson());

      try {
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          showCustomToast(
              context, 'GK Posted Successfully for all selected students!');
          Navigator.pop(context);
        } else {
          showCustomToast(context, 'Failed to post GK for $student!');
        }
      } catch (e) {
        showCustomToast(context, 'Error occurred for $student');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset('assets/back_button.png', height: 50),
            ),
            const SizedBox(width: 20),
            const Text(
              'Add GK',
              style: TextStyle(
                color: Color(0xFF48116A),
                fontSize: 25,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            _buildMultiSelectDropdown(),
            const SizedBox(height: 15),
            _buildTextField(titleController, 'Title'),
            const SizedBox(height: 15),
            _buildTextField(descriptionController, 'Description', maxLines: 5),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => _showImagePickerDialog(context),
                child: Container(
                  width: double.infinity,
                  height: 168,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: formData.photo != null
                        ? Image.network(formData.photo!)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/camera@3x.png',
                                  width: 46, height: 37),
                              const SizedBox(height: 10),
                              const Text('Upload Image',
                                  style: TextStyle(fontSize: 14)),
                              const SizedBox(height: 5),
                              const Text('Click Here',
                                  style: TextStyle(fontSize: 10)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'This post will only be visible to the\nstudents you teach',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.red, fontFamily: 'Poppins'),
              ),
            ),
            const SizedBox(height: 20),
            _buildPostButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectDropdown() {
    bool hasStudents = names.isNotEmpty;

    return GestureDetector(
      onTap: hasStudents ? null : () {}, // Prevents tapping when no students
      child: AbsorbPointer(
        absorbing: !hasStudents, // Disables interaction
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: MultiSelectDialogField(
            items: hasStudents
                ? names.map((e) => MultiSelectItem(e, e)).toList()
                : [],
            title: const Text("Select Students"),
            selectedColor: Colors.purple,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            buttonText: hasStudents
                ? const Text("Select Students")
                : const Text(
                    "No students assigned yet",
                    style: TextStyle(color: Colors.grey), // Gray out text
                  ),
            dialogWidth: _calculateDialogWidth(),
            dialogHeight: _calculateDialogHeight(),
            onConfirm: (values) {
              setState(() {
                selectedStudents = List<String>.from(values);
              });
            },
            chipDisplay: MultiSelectChipDisplay(),
            listType: MultiSelectListType.LIST,
          ),
        ),
      ),
    );
  }

// Function to calculate dialog width based on text length
  double _calculateDialogWidth() {
    double baseWidth = 200; // Minimum width
    double maxWidth = 400; // Maximum width
    double avgTextLength = names.isNotEmpty
        ? names.map((e) => e.length).reduce((a, b) => a + b) / names.length
        : 10;
    return (baseWidth + avgTextLength * 10).clamp(baseWidth, maxWidth);
  }

// Function to calculate dialog height based on list size
  double _calculateDialogHeight() {
    int minItems = 1;
    int maxItems = 10;
    int itemCount = names.length.clamp(minItems, maxItems);
    return (10.0 * itemCount) + 50; // Adjusting height dynamically
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: hint,
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(
                width: 0.5, color: Color.fromARGB(255, 237, 234, 234)),
          ),
        ),
      ),
    );
  }

  Widget _buildPostButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          submitForm();
        },
        child: Image.asset(
          'assets/postbutton.png',
          width: double.infinity,
          height: 70,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _showImagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogButton('Camera', Colors.lightBlue.shade100, () {
                  Navigator.pop(context);
                  handleUploadFromCamera();
                }),
                const SizedBox(height: 16),
                _buildDialogButton('Upload File', Colors.orange.shade100, () {
                  Navigator.pop(context);
                  handleUploadFromGallery();
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _buildDialogButton(String text, Color color, VoidCallback onPressed) {
  return Container(
    width: 200,
    height: 50,
    decoration:
        BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
    child: TextButton(
      onPressed: onPressed,
      child: Text(text,
          style: const TextStyle(
              fontSize: 18, color: Colors.black, fontFamily: 'Poppins')),
    ),
  );
}
