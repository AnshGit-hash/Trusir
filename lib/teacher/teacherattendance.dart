import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusir/common/api.dart';
import 'package:trusir/common/custom_toast.dart';
import 'package:trusir/teacher/teacher_facilities.dart';

class TeacherAttendancePage extends StatefulWidget {
  final List<StudentProfile> studentprofile;
  const TeacherAttendancePage({super.key, required this.studentprofile});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  DateTime _selectedDate = DateTime.now();
  int selectedStudentIndex = 0;
  Map<int, Map<String, String>> _attendanceData = {};
  Map<String, int> _summaryData = {};
  List<String> weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  String? selectedslotID = '';
  String? teacheruserID;
  List<Map<String, String>> slots = [];
  String? selectedStudent;
  String? selectedUserID;
  List<String> names = [];
  Map<String, String> nameUserMap = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _extractStudentData();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  void _extractStudentData() {
    if (widget.studentprofile.isEmpty) {
      setState(() => names = []);
      return;
    }

    setState(() {
      names = widget.studentprofile.map((student) => student.name).toList();
      nameUserMap = {
        for (var student in widget.studentprofile) student.name: student.userID
      };
      selectedUserID = nameUserMap[names[0]];
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() => teacheruserID = prefs.getString('id'));

      final courses = await _fetchCourses();
      setState(() => selectedslotID = _getMatchingSlotID(courses));

      if (selectedslotID != null) {
        await _fetchAttendanceData(selectedslotID!);
      } else {
        _showNoDataMessage();
      }
    } catch (error) {
      _showErrorSnackbar('Initialization error: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<Course>> _fetchCourses() async {
    final url = Uri.parse('$baseUrl/get-individual-slots/$selectedUserID');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        slots = data.map((course) {
          return {
            'courseName': course['courseName'] as String,
            'timeSlot': course['timeSlot'] as String,
            'slotID': course['id'].toString(),
          };
        }).toList();
      });
      return data.map((json) => Course.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch courses');
    }
  }

  String? _getMatchingSlotID(List<Course> courses) {
    if (teacheruserID == null) return null;
    for (final course in courses) {
      if (course.teacherID == teacheruserID) {
        return slots.firstWhere(
          (slot) => slot['slotID'] == course.id.toString(),
        )['slotID'];
      }
    }
    return null;
  }

  DateTime get _firstDayOfMonth =>
      DateTime(_selectedDate.year, _selectedDate.month, 1);
  int get _daysInMonth =>
      DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
  int get _startingWeekday => _firstDayOfMonth.weekday % 7;
  String get _monthYearString =>
      "${_getMonthName(_selectedDate.month)} ${_selectedDate.year}";

  Future<void> _fetchAttendanceData(String slotID) async {
    setState(() => _isLoading = true);
    try {
      final month = _selectedDate.month;
      final year = _selectedDate.year.toString();
      final apiResponse = await _attendanceConvert(month, year, slotID);

      if (apiResponse.isEmpty || !apiResponse.containsKey(year)) {
        _showNoDataMessage();
        return;
      }

      final monthKey = month.toString();
      if (apiResponse[year].containsKey(monthKey)) {
        setState(() {
          _attendanceData =
              (apiResponse[year][monthKey] as Map<String, dynamic>)
                  .map<int, Map<String, String>>((date, idAndStatus) {
            return MapEntry(
                int.parse(date), idAndStatus as Map<String, String>);
          });
          _updateSummary();
        });
      } else {
        _showNoDataMessage();
      }
    } catch (error) {
      _showErrorSnackbar('Error fetching attendance: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _attendanceConvert(
      int month, String year, String slotID) async {
    final records = await _fetchAttendanceRecords(
      year: int.parse(year),
      month: month,
      slotID: slotID,
    );
    return _attendanceDataStructure(records);
  }

  Future<List<StudentAttendanceRecord>> _fetchAttendanceRecords({
    required String slotID,
    required int year,
    required int month,
  }) async {
    final url = Uri.parse(
        'https://admin.trusir.com/view-attendance/$slotID/$year/${month.toString().padLeft(2, '0')}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => StudentAttendanceRecord.fromJson(json))
          .toList();
    } else {
      throw Exception(
          'Failed to load attendance records. Status: ${response.statusCode}');
    }
  }

  Map<String, dynamic> _attendanceDataStructure(
      List<StudentAttendanceRecord> records) {
    Map<String, Map<String, Map<String, Map<String, String>>>>
        attendanceHierarchy = {};

    for (var record in records) {
      DateTime dateTime = DateTime.parse(record.date);
      String year = dateTime.year.toString();
      String month = dateTime.month.toString();
      String day = dateTime.day.toString();

      attendanceHierarchy.putIfAbsent(year, () => {});
      attendanceHierarchy[year]!.putIfAbsent(month, () => {});
      attendanceHierarchy[year]![month]!.putIfAbsent(
          day,
          () => {
                "id": record.slotID.toString(),
                "status": record.status,
                "date": record.date,
                "day": _getDayName(dateTime.weekday),
              });
    }
    return attendanceHierarchy;
  }

  String _getDayName(int weekday) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[weekday % 7];
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  void _showNoDataMessage() {
    showCustomToast(context, 'No attendance data available.');
  }

  void _showErrorSnackbar(String message) {
    showCustomToast(context, message);
  }

  Future<void> _navigateToYearMonthPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YearMonthPicker(
          selectedYear: _selectedDate.year,
          selectedMonth: _selectedDate.month,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDate =
            DateTime(result['year'], result['month'], _selectedDate.day);
        _fetchAttendanceData(selectedslotID!);
      });
    }
  }

  Future<void> _updateAttendanceStatus({
    required String status,
    required String date,
    required String slotID,
  }) async {
    try {
      final endpoint = status == 'P'
          ? 'mark-present'
          : status == 'A'
              ? 'mark-absent'
              : 'mark-holiday';

      final url = Uri.parse(
          'https://admin.trusir.com/$endpoint/$date/$selectedUserID/$slotID');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        showCustomToast(context, data['message']);
        await _fetchAttendanceData(selectedslotID!);
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorSnackbar('Error updating status: $error');
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedDate = _selectedDate.month == 1
          ? DateTime(_selectedDate.year - 1, 12)
          : DateTime(_selectedDate.year, _selectedDate.month - 1);
      _fetchAttendanceData(selectedslotID!);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = _selectedDate.month == 12
          ? DateTime(_selectedDate.year + 1, 1)
          : DateTime(_selectedDate.year, _selectedDate.month + 1);
      _fetchAttendanceData(selectedslotID!);
    });
  }

  void _updateSummary() {
    int totalClassesTaken = 0;
    int presentCount = 0;
    int absentCount = 0;
    int classNotTakenCount = 0;

    _attendanceData.forEach((_, dateData) {
      String? status = dateData['status'];
      if (status != null) {
        totalClassesTaken++;
        if (status == 'P') {
          presentCount++;
        } else if (status == 'A') {
          absentCount++;
        } else if (status == 'H') {
          classNotTakenCount++;
        }
      }
    });

    setState(() {
      _summaryData = {
        'total_classes_taken': totalClassesTaken,
        'present': presentCount,
        'absent': absentCount,
        'No class': classNotTakenCount,
      };
    });
  }

  void _showAttendanceDialog({
    required int day,
    required String? id,
    required String? date,
    required String? dayName,
    required String status,
  }) {
    final isSunday = dayName == 'Sunday';
    final isHoliday = status.contains('H');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Attendance for $day"),
        content: DropdownButton<String>(
          value: status,
          items: [
            if (!isSunday || isHoliday)
              const DropdownMenuItem(value: 'P', child: Text('Present')),
            if (!isHoliday)
              const DropdownMenuItem(value: 'A', child: Text('Absent')),
            if (!isSunday && !isHoliday)
              const DropdownMenuItem(value: 'H', child: Text('Holiday')),
          ].whereType<DropdownMenuItem<String>>().toList(),
          onChanged: (newStatus) async {
            Navigator.pop(context);
            if (newStatus == 'H') {
              _showErrorSnackbar('Holiday can only be marked by admin');
            } else if (date != null && id != null) {
              await _updateAttendanceStatus(
                status: newStatus!,
                date: date,
                slotID: id,
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb =
        MediaQuery.of(context).size.width > 800; // Increased breakpoint for web
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate calendar width - fixed maximum size for web
    final calendarWidth = isWeb
        ? screenWidth * 0.5 > 500
            ? 500
            : screenWidth * 0.5
        : screenWidth - 40;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: EdgeInsets.only(left: isWeb ? 20.0 : 10.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Image.asset('assets/back_button.png', height: 50),
              ),
              if (!isWeb) const SizedBox(width: 20),
              Text(
                'Attendance',
                style: TextStyle(
                  color: const Color(0xFF48116A),
                  fontSize: isWeb ? 28 : 25,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: isWeb ? 80 : 70,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 40.0 : 15.0,
                  vertical: isWeb ? 20 : 0,
                ),
                child: isWeb
                    ? _buildWebLayout(theme, calendarWidth as double)
                    : _buildMobileLayout(theme, calendarWidth as double),
              ),
            ),
    );
  }

  Widget _buildWebLayout(ThemeData theme, double calendarWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar Section - Left Side
        SizedBox(
          width: calendarWidth,
          child: Column(
            children: [
              if (names.isNotEmpty) _buildStudentSelector(theme),
              if (names.isEmpty) _buildNoStudentsMessage(theme),
              const SizedBox(height: 20),
              _buildCalendar(theme, calendarWidth),
            ],
          ),
        ),

        // Summary Section - Right Side
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _buildSummaryCard(
                      'Present',
                      _summaryData['present'] ?? 0,
                      Colors.green,
                      theme,
                      true,
                    ),
                    _buildSummaryCard(
                      'Absent',
                      _summaryData['absent'] ?? 0,
                      Colors.red,
                      theme,
                      true,
                    ),
                    _buildSummaryCard(
                      'Holiday',
                      _summaryData['No class'] ?? 0,
                      Colors.grey,
                      theme,
                      true,
                    ),
                    _buildSummaryCard(
                      'Total Classes',
                      _summaryData['total_classes_taken'] ?? 0,
                      Colors.amber,
                      theme,
                      true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme, double calendarWidth) {
    return Column(
      children: [
        if (names.isNotEmpty) _buildStudentSelector(theme),
        if (names.isEmpty) _buildNoStudentsMessage(theme),
        _buildCalendar(theme, calendarWidth),
        const SizedBox(height: 20),
        SizedBox(
          child: Column(
            children: [
              Row(
                children: [
                  _buildSummaryCard(
                    'Present',
                    _summaryData['present'] ?? 0,
                    Colors.green,
                    theme,
                    true,
                  ),
                  const SizedBox(width: 5),
                  _buildSummaryCard(
                    'Absent',
                    _summaryData['absent'] ?? 0,
                    Colors.red,
                    theme,
                    true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSummaryCard(
                    'Holiday',
                    _summaryData['holiday'] ?? 0,
                    Colors.grey,
                    theme,
                    true,
                  ),
                  const SizedBox(width: 5),
                  _buildSummaryCard(
                    'Total Classes',
                    _summaryData['total_classes_taken'] ?? 0,
                    Colors.amber,
                    theme,
                    true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(ThemeData theme, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calendar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: _prevMonth,
              ),
              TextButton(
                onPressed: _navigateToYearMonthPicker,
                child: Text(
                  _monthYearString,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _nextMonth,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime.now();
                    _fetchAttendanceData(selectedslotID!);
                  });
                },
                child: const Text(
                  'Today',
                  style: TextStyle(
                    color: Color(0xFF48116A),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          // Day Headers
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays
                  .map((day) => SizedBox(
                        width: width / 7 - 8,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF48116A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: _startingWeekday + _daysInMonth,
            itemBuilder: (context, index) {
              if (index < _startingWeekday) {
                return const SizedBox.shrink();
              }

              int day = index - _startingWeekday + 1;
              bool isToday = day == DateTime.now().day &&
                  _selectedDate.month == DateTime.now().month &&
                  _selectedDate.year == DateTime.now().year;

              String status = _attendanceData[day]?['status'] ?? "no_data";
              String? id = _attendanceData[day]?['id'];
              String? date = _attendanceData[day]?['date'];
              String? dayName = _attendanceData[day]?['day'];

              return GestureDetector(
                onTap: () {
                  if (id != null && date != null) {
                    _showAttendanceDialog(
                      day: day,
                      id: id,
                      date: date,
                      dayName: dayName,
                      status: status,
                    );
                  } else {
                    _showErrorSnackbar("No ID found for this date!");
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _getStatusColor(status, theme),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday ? theme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: _getTextColor(status, theme),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoStudentsMessage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        'No Students Assigned Yet',
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildStudentSelector(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.cardColor,
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: List.generate(names.length, (index) {
            bool isSelected = selectedStudentIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedStudentIndex = index;
                  selectedUserID = nameUserMap[names[index]];
                  _initializeData();
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? theme.primaryColor : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  names[index],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case "P":
        return Colors.green;
      case "A":
        return Colors.red;
      case "H":
        return Colors.grey;
      default:
        return theme.cardColor;
    }
  }

  Color _getTextColor(String status, ThemeData theme) {
    return status == "no_data"
        ? theme.textTheme.bodyLarge?.color ?? Colors.black
        : Colors.white;
  }

  Widget _buildSummaryCard(
    String title,
    int count,
    Color color,
    ThemeData theme,
    bool isWeb,
  ) {
    return Container(
      width: isWeb ? 180 : 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class YearMonthPicker extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;

  const YearMonthPicker({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear - 5 + index);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Year and Month'),
      ),
      body: ListView(
        children: [
          for (final year in years)
            ExpansionTile(
              title: Text('$year', style: const TextStyle(fontSize: 18)),
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  children: List.generate(12, (month) {
                    final monthName =
                        DateFormat('MMM').format(DateTime(year, month + 1));
                    return InkWell(
                      onTap: () => Navigator.pop(
                          context, {'year': year, 'month': month + 1}),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              year == selectedYear && month + 1 == selectedMonth
                                  ? theme.primaryColor.withOpacity(0.2)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            monthName,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Model classes
class StudentAttendanceRecord {
  final int id;
  final String slotTime;
  final String amountAddedtoTeacher;
  final String studentID;
  final String teacherID;
  final String date;
  final String slotID;
  final String status;

  StudentAttendanceRecord({
    required this.id,
    required this.slotTime,
    required this.amountAddedtoTeacher,
    required this.studentID,
    required this.teacherID,
    required this.date,
    required this.slotID,
    required this.status,
  });

  factory StudentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceRecord(
      id: json['id'],
      slotTime: json['slotTime'] ?? 'No time alloted',
      amountAddedtoTeacher: json['amount_added_to_teacher'],
      studentID: json['studentID'],
      teacherID: json['teacherID'],
      date: json['date'],
      slotID: json['slotID'],
      status: json['status'],
    );
  }
}

class Course {
  final int id;
  final String teacherID;

  Course({
    required this.id,
    required this.teacherID,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      teacherID: json['teacherID'],
    );
  }
}
