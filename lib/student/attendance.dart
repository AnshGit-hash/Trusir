import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:trusir/common/api.dart';

import '../common/custom_toast.dart';

class AttendanceRecord {
  final int id;
  final String slotTime;
  final String amountAddedtoTeacher;
  final String studentID;
  final String teacherID;
  final String date;
  final String slotID;
  final String status;

  AttendanceRecord({
    required this.id,
    required this.slotTime,
    required this.amountAddedtoTeacher,
    required this.studentID,
    required this.teacherID,
    required this.date,
    required this.slotID,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
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
  final String courseID;
  final String courseName;
  final String teacherName;
  final String teacherID;
  final String studentID;
  final String image;
  final String studentName;
  final String timeSlot;

  Course({
    required this.id,
    required this.courseID,
    required this.courseName,
    required this.teacherName,
    required this.teacherID,
    required this.studentID,
    required this.image,
    required this.studentName,
    required this.timeSlot,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      courseID: json['courseID'],
      courseName: json['courseName'],
      teacherName: json['teacherName'],
      teacherID: json['teacherID'],
      studentID: json['StudentID'],
      image: json['image'],
      studentName: json['StudentName'],
      timeSlot: json['timeSlot'],
    );
  }
}

class AttendancePage extends StatefulWidget {
  final String userID;
  const AttendancePage({super.key, required this.userID});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime _selectedDate = DateTime.now();
  int selectedCourseIndex = 0;
  int selectedSlotIndex = 0;
  bool isWeb = false;
  Map<int, Map<String, String>> _attendanceData = {};
// Day: Status
  Map<String, int> _summaryData = {}; // Summary details
  List<String> weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  List<Map<String, String>> slots = [];
  String? selectedslotID = '';

  Future<List<Course>> fetchCourses() async {
    final url = Uri.parse(
        '$baseUrl/get-individual-slots/${widget.userID}'); // Replace with your API URL
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (mounted) {
        setState(() {
          slots = data.map((course) {
            return {
              'courseName': course['courseName'] as String,
              'timeSlot': course['timeSlot'] as String,
              'slotID': course['id']
                  .toString(), // Converting 'id' to String for uniformity
            };
          }).toList();
        });
      }
      setState(() {
        selectedslotID = slots[0]['slotID'];
      });
      print(selectedslotID);
      return data.map((json) => Course.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch courses');
    }
  }

  DateTime get _firstDayOfMonth {
    return DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  int get _daysInMonth {
    return DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
  }

  int get _startingWeekday {
    return _firstDayOfMonth.weekday % 7; // Adjust for week starting Sunday
  }

  List<int> get dates {
    return List.generate(_daysInMonth, (index) => index + 1);
  }

  String get _monthYearString {
    return "${getMonthName(_selectedDate.month)} ${_selectedDate.year}";
  }

  @override
  void initState() {
    super.initState();
    initializeData();
  }

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

  Future<void> initializeData() async {
    try {
      await fetchCourses(); // Wait for fetchCourses to complete
      _fetchAttendanceData(
          selectedslotID!); // Call _fetchAttendanceData after fetchCourses
    } catch (error) {
      print('Error during initialization: $error');
    }
  }

  Future<List<AttendanceRecord>> fetchAttendanceRecords({
    required String slotID,
    required int year,
    required int month,
  }) async {
    final url = Uri.parse(
        'https://admin.trusir.com/view-attendance/$slotID/$year/${month.toString().padLeft(2, '0')}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AttendanceRecord.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load attendance records. Status: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching attendance records: $error');
    }
  }

// Process the new API response format
  Map<int, Map<String, String>> processAttendanceData(
      List<AttendanceRecord> records) {
    Map<int, Map<String, String>> processedData = {};

    for (var record in records) {
      // Extract the day from the date string (format: "2025-04-10")
      int day = int.parse(record.date.split('-')[2]);

      // Parse the full date to get the weekday
      DateTime date = DateTime.parse(record.date);
      String dayName = _getDayName(date.weekday);

      // Map the status to match your existing UI expectations
      String status = record.status == 'P'
          ? 'present'
          : (record.status == 'A' ? 'absent' : 'holiday');

      processedData[day] = {
        'id': record.slotID.toString(),
        'status': status,
        'date': record.date,
        'day': dayName, // Add the day name here
      };
    }

    return processedData;
  }

  Future<void> _fetchAttendanceData(String selectedslotID) async {
    final month = _selectedDate.month;
    final year = _selectedDate.year;

    setState(() {
      _attendanceData.clear(); // Clear old data before fetching new data
    });

    try {
      final records = await fetchAttendanceRecords(
        slotID: selectedslotID,
        year: year,
        month: month,
      );

      if (records.isEmpty) {
        _showNoDataMessage();
        return;
      }

      setState(() {
        _attendanceData = processAttendanceData(records);
        print(_attendanceData);
      });

      _updateSummary(); // Update summary after fetching data
    } catch (error) {
      print("Error fetching attendance data: $error");
      _showNoDataMessage();
    }
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

  void _showNoDataMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No attendance data available.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> markHoliday({
    required String date,
    required String slotID,
  }) async {
    final url = Uri.parse(
        'https://admin.trusir.com/mark-holiday/$date/${widget.userID}/$slotID');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        showCustomToast(context, data['message']);
        setState(() {
          // Update the status locally
          _fetchAttendanceData(selectedslotID!);
          _updateSummary(); // Update the summary
        });
      } else {
        throw Exception('Failed to mark absent Status: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error while marking absent: $error');
    }
  }

  Future<void> markAbsent({
    required String date,
    required String slotID,
  }) async {
    final url = Uri.parse(
        'https://admin.trusir.com/mark-absent/$date/${widget.userID}/$slotID');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        showCustomToast(context, data['message']);
        setState(() {
          // Update the status locally
          _fetchAttendanceData(selectedslotID!);
          _updateSummary(); // Update the summary
        });
      } else {
        throw Exception('Failed to mark absent Status: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error while marking absent: $error');
    }
  }

  Future<void> markPresent({
    required String date,
    required String slotID,
  }) async {
    final url = Uri.parse(
        'https://admin.trusir.com/mark-present/$date/${widget.userID}/$slotID');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        showCustomToast(context, data['message']);
        setState(() {
          // Update the status locally
          _fetchAttendanceData(selectedslotID!);
          _updateSummary(); // Update the summary
        });
      } else {
        throw Exception('Failed to mark absent Status: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error while marking absent: $error');
    }
  }

  void _navigateToYearMonthPicker(BuildContext context) async {
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
        _updateSummary();
      });
    }
  }

  void _prevMonth() {
    setState(() {
      if (_selectedDate.month == 1) {
        _selectedDate = DateTime(
            _selectedDate.year - 1, 12); // Go to December of the previous year
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      }
      _fetchAttendanceData(selectedslotID!);
    });
  }

  void _nextMonth() {
    setState(() {
      if (_selectedDate.month == 12) {
        _selectedDate = DateTime(
            _selectedDate.year + 1, 1); // Go to January of the next year
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      }
      _fetchAttendanceData(selectedslotID!);
    });
  }

  void _updateSummary() {
    int totalClassesTaken = 0;
    int presentCount = 0;
    int absentCount = 0;
    int classNotTakenCount = 0;

    _attendanceData.forEach((_, dateData) {
      // Extract the status from the nested map
      String? status = dateData['status'];

      if (status != null) {
        totalClassesTaken++;
        if (status == 'present') {
          presentCount++;
        } else if (status == 'absent') {
          absentCount++;
        } else if (status == 'holiday') {
          classNotTakenCount++;
        }
      }
    });

    setState(() {
      _summaryData = {
        'total_classes_taken': totalClassesTaken,
        'present': presentCount,
        'absent': absentCount,
        'holiday': classNotTakenCount,
      };
    });
  }

  String getMonthName(int month) {
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

  @override
  Widget build(BuildContext context) {
    isWeb = MediaQuery.of(context).size.width > 600;
    final theme = Theme.of(context);

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
              if (!isWeb)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              if (!isWeb) const SizedBox(width: 20),
              Text(
                'Attendance',
                style: TextStyle(
                  color: theme.primaryColor,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 40.0 : 15.0,
                vertical: 20.0,
              ),
              child: isWeb ? _buildWebLayout(theme) : _buildMobileLayout(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar Section
        Container(
          width: 500, // Fixed width for web
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSlotList(theme),
              const SizedBox(height: 20),
              _buildCalendarHeader(theme),
              const SizedBox(height: 12),
              _buildCalendarGrid(theme),
            ],
          ),
        ),

        const SizedBox(width: 40),

        // Summary Section
        SizedBox(
          width: 300,
          child: Column(
            children: [
              _buildSummaryCard(
                'Present',
                _summaryData['present'] ?? 0,
                Colors.green,
                theme,
                true,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                'Absent',
                _summaryData['absent'] ?? 0,
                Colors.red,
                theme,
                true,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                'Holiday',
                _summaryData['holiday'] ?? 0,
                Colors.grey,
                theme,
                true,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                'Total Classes',
                _summaryData['total_classes_taken'] ?? 0,
                Colors.amber,
                theme,
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSlotList(theme),
        const SizedBox(height: 20),
        // Calendar Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildCalendarHeader(theme),
              const SizedBox(height: 12),
              _buildCalendarGrid(theme),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Summary Section
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _buildSummaryCard(
              'Present',
              _summaryData['present'] ?? 0,
              Colors.green,
              theme,
              false,
            ),
            _buildSummaryCard(
              'Absent',
              _summaryData['absent'] ?? 0,
              Colors.red,
              theme,
              false,
            ),
            _buildSummaryCard(
              'Holiday',
              _summaryData['holiday'] ?? 0,
              Colors.grey,
              theme,
              false,
            ),
            _buildSummaryCard(
              'Total Classes',
              _summaryData['total_classes_taken'] ?? 0,
              Colors.amber,
              theme,
              false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlotList(ThemeData theme) {
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
          children: List.generate(slots.length, (index) {
            bool isSelected = selectedSlotIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedSlotIndex = index;
                  selectedslotID = slots[index]['slotID']!;
                  _fetchAttendanceData(selectedslotID!);
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
                  '${slots[index]['courseName']!}, ${slots[index]['timeSlot']!}',
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

  Widget _buildCalendarHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _prevMonth,
        ),
        TextButton(
          onPressed: () => _navigateToYearMonthPicker,
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
          child: Text(
            'Today',
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    return Column(
      children: [
        // Day Headers
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map((day) => SizedBox(
                      width: 40,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.primaryColor,
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
            if (index < _startingWeekday) return const SizedBox.shrink();

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
                  showCustomToast(context, "No ID found for this date!");
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
    );
  }

  void _showAttendanceDialog(
      {required String status,
      required String? dayName,
      required int day,
      required String id,
      required String date}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Attendance for $day"),
        content: DropdownButton<String>(
          value: status,
          items: const [
            DropdownMenuItem(value: 'present', child: Text('Present')),
            DropdownMenuItem(value: 'absent', child: Text('Absent')),
            DropdownMenuItem(value: 'holiday', child: Text('Holiday')),
          ],
          onChanged: (newStatus) {
            if (newStatus == 'absent') {
              // Close dialog before API call
              try {
                markAbsent(
                  date: date,
                  slotID: id,
                );
                Navigator.pop(context);
              } catch (e) {
                showCustomToast(context, 'Failed to mark absent: $e');
                Navigator.pop(context);
              }
            } else if (newStatus == 'present') {
              try {
                markPresent(
                  date: date,
                  slotID: id,
                );
                Navigator.pop(context);
              } catch (e) {
                showCustomToast(context, 'Failed to mark present: $e');
                Navigator.pop(context);
              }
            } else if (newStatus == 'holiday') {
              showCustomToast(context, 'Holiday can only be marked from admin');
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}

Widget _buildSummaryCard(
  String title,
  int count,
  Color color,
  ThemeData theme,
  bool isWeb,
) {
  return Container(
    width: isWeb ? 300 : 180,
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

Color _getStatusColor(String status, ThemeData theme) {
  switch (status) {
    case "present":
      return Colors.green;
    case "absent":
      return Colors.red;
    case "holiday":
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

class YearMonthPicker extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;

  const YearMonthPicker(
      {super.key, required this.selectedYear, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;
    final List<int> years =
        List.generate(currentYear - 2000 + 1, (index) => 2000 + index);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Year and Month'),
      ),
      body: ListView.builder(
        itemCount: years.length,
        itemBuilder: (context, index) {
          int year = years[index];
          return ExpansionTile(
            title: Text('$year'),
            children: List.generate(12, (monthIndex) {
              return ListTile(
                title: Text('Month: ${monthIndex + 1}'),
                onTap: () {
                  Navigator.pop(
                      context, {'year': year, 'month': monthIndex + 1});
                },
              );
            }),
          );
        },
      ),
    );
  }
}
