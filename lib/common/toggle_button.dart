import 'package:flutter/material.dart';

class FilterSwitch extends StatefulWidget {
  final String option1;
  final String option2;
  final String option3;
  final String option4;
  final ValueChanged<int> onChanged;
  final int initialSelectedIndex;

  const FilterSwitch({
    required this.option1,
    required this.option2,
    required this.option3,
    required this.option4,
    required this.onChanged,
    this.initialSelectedIndex = 0,
    super.key,
  });

  @override
  FilterSwitchState createState() => FilterSwitchState();
}

class FilterSwitchState extends State<FilterSwitch> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onOptionTap(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      widget.onChanged(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 600;
    return Center(
      child: Container(
        height: 50,
        width: isWeb ? 600 : 380,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              left: isWeb
                  ? (_selectedIndex * (600 / 4)) + 4
                  : (_selectedIndex * (380 / 4)) + 4,
              top: 4,
              child: Container(
                width: (isWeb ? 600 / 4 : 380 / 4) - 8,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onOptionTap(0),
                    child: Center(
                      child: Text(
                        widget.option1,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          color:
                              _selectedIndex == 0 ? Colors.white : Colors.black,
                          fontWeight: _selectedIndex == 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: isWeb ? 15 : 10,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onOptionTap(1),
                    child: Center(
                      child: Text(
                        widget.option2,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          color:
                              _selectedIndex == 1 ? Colors.white : Colors.black,
                          fontWeight: _selectedIndex == 1
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: isWeb ? 15 : 10,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onOptionTap(2),
                    child: Center(
                      child: Text(
                        widget.option3,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          color:
                              _selectedIndex == 2 ? Colors.white : Colors.black,
                          fontWeight: _selectedIndex == 2
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: isWeb ? 15 : 10,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onOptionTap(3),
                    child: Center(
                      child: Text(
                        widget.option4,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          color:
                              _selectedIndex == 3 ? Colors.white : Colors.black,
                          fontWeight: _selectedIndex == 3
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: isWeb ? 15 : 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
