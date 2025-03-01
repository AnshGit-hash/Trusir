import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/teacher/teacher_facilities.dart';

class AddNoticeTeacher extends StatefulWidget {
  final List<StudentProfile> studentprofile;
  const AddNoticeTeacher({super.key, required this.studentprofile});

  @override
  State<AddNoticeTeacher> createState() => _AddNoticeTeacherState();
}

class _AddNoticeTeacherState extends State<AddNoticeTeacher> {
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<String> selectedStudents = [];
  List<String> names = [];
  List<StudentProfile> students = [];
  Map<String, String> nameUserMap = {};

  void extractStudentData(List<StudentProfile> students, List<String> names,
      Map<String, String> nameUserIDMap) {
    for (var student in students) {
      names.add(student.name);
      nameUserIDMap[student.name] = student.userID;
    }
  }

  Future<void> _onPost() async {
    final prefs = await SharedPreferences.getInstance();
    final teacherUserID = prefs.getString('userID');
    final String currentDate = DateTime.now().toIso8601String();

    final url = Uri.parse('$baseUrl/api/add-notice');

    try {
      for (String student in selectedStudents) {
        String? studentUserID = nameUserMap[student];
        final payload = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'posted_on': currentDate,
          'to': studentUserID,
          'from': teacherUserID,
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          print("Failed to post notice for $studentUserID: ${response.body}");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notices posted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      students = widget.studentprofile;
      extractStudentData(students, names, nameUserMap);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
              'Add Notice',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMultiSelectDropdown(),
                  const SizedBox(height: 20),
                  _buildTextField('Title', _titleController),
                  const SizedBox(height: 20),
                  _buildDescriptionField(),
                ],
              ),
            ),
          ),
          _buildPostButton(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
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

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 5,
      decoration: _inputDecoration('Description'),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(color: Colors.blue),
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(width: 1, color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(width: 1, color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(width: 1, color: Colors.blue),
      ),
    );
  }

  Widget _buildPostButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: () {
          if (_titleController.text.isEmpty ||
              _descriptionController.text.isEmpty ||
              selectedStudents.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please fill in all fields')),
            );
          } else {
            _onPost();
          }
        },
        child: Image.asset(
          'assets/postbutton.png',
          height: 80,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
