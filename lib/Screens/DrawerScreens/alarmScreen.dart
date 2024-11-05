import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartband/Screens/Widgets/loading.dart';
import 'package:smartband/pushnotifications.dart';
import 'package:workmanager/workmanager.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ProfilepageState();
}

class _ProfilepageState extends ConsumerState<ReminderScreen> {
  late DateTime _selectedDate;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToSelectedDate());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate() {
    if (_scrollController.hasClients) {
      final int dayIndex = _selectedDate.day - 1;
      _scrollController.animateTo(
        dayIndex * 60.0, // Assuming each date item has a width of 60
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Reminder',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount:
                    DateTime(_selectedDate.year, _selectedDate.month + 1, 0)
                        .day,
                itemBuilder: (context, index) {
                  final date = DateTime(
                      _selectedDate.year, _selectedDate.month, index + 1);
                  final isSelected = date.day == _selectedDate.day;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      width: 60,
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.blue : Colors.transparent,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(date),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reminders')
                  .where('userId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: GradientLoadingIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No reminders for this date.'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final reminder = snapshot.data!.docs[index];
                    final reminderData =
                        reminder.data() as Map<String, dynamic>;
                    final reminderDate =
                        DateFormat('dd-MM-yyyy').parse(reminderData['date']);
                    bool showReminder = false;

                    switch (reminderData['repeat']) {
                      case 'No Repeat':
                        showReminder =
                            reminderDate.year == _selectedDate.year &&
                                reminderDate.month == _selectedDate.month &&
                                reminderDate.day == _selectedDate.day;
                        break;
                      case 'Daily':
                        showReminder =
                            _selectedDate.isAtSameMomentAs(reminderDate) ||
                                _selectedDate.isAfter(reminderDate);
                        break;
                      case 'Weekly':
                        final difference =
                            _selectedDate.difference(reminderDate).inDays;
                        showReminder = difference % 7 == 0;
                        break;
                      case 'Monthly':
                        showReminder = reminderDate.day == _selectedDate.day;
                        break;
                      case 'Yearly':
                        showReminder = reminderDate.day == _selectedDate.day &&
                            reminderDate.month == _selectedDate.month;
                        break;
                    }

                    if (showReminder) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildReminderCard(
                          reminderData['title'],
                          reminderData['time'],
                          Icons.alarm,
                          reminderData,
                          reminder.id,
                        ),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AddReminderDialog(),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    'Add Reminder',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(String title, String time, IconData icon,
      Map<String, dynamic> reminderData, String docId) {
    final now = DateTime.now();
    final reminderTime = DateFormat('hh:mm a').parse(time);
    final reminderDateTime = DateTime(
        now.year, now.month, now.day, reminderTime.hour, reminderTime.minute);

    Color cardColor;
    if (reminderDateTime.isBefore(now)) {
      cardColor = Colors.grey;
    } else if (reminderDateTime.difference(now).inHours < 1) {
      cardColor = Colors.red;
    } else if (reminderDateTime.difference(now).inHours < 3) {
      cardColor = Colors.orange;
    } else {
      cardColor = Colors.yellow;
    }

    return Card(
      color: cardColor,
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) =>
                EditReminderDialog(reminderData: reminderData, docId: docId),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(time),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }
}

class AddReminderDialog extends StatefulWidget {
  @override
  _AddReminderDialogState createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String selectedRepeat = 'No Repeat';
  final TextEditingController _titleController = TextEditingController();
  bool isSaveButtonEnabled = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _checkSaveButtonState();
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        _checkSaveButtonState();
      });
    }
  }

  void _checkSaveButtonState() {
    setState(() {
      isSaveButtonEnabled = _titleController.text.isNotEmpty &&
          selectedDate != null &&
          selectedTime != null;
    });
  }

  Future<void> _saveReminder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final reminderData = {
        'title': _titleController.text,
        'date': DateFormat('dd-MM-yyyy').format(selectedDate!),
        'time': DateFormat('hh:mm a').format(
            DateTime(2022, 1, 1, selectedTime!.hour, selectedTime!.minute)),
        'repeat': selectedRepeat,
        'userId': user.uid,
      };

      try {
        await FirebaseFirestore.instance
            .collection('reminders')
            .add(reminderData);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder saved successfully')),
        );
      } catch (e) {
        print('Error saving reminder: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save reminder')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Reminder',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Eg. Water time',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => _checkSaveButtonState(),
            ),
            SizedBox(height: 15),
            Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              readOnly: true,
              controller: TextEditingController(
                text: selectedDate != null
                    ? DateFormat('dd-MM-yyyy').format(selectedDate!)
                    : '',
              ),
              decoration: InputDecoration(
                hintText: 'Choose calendar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
            ),
            SizedBox(height: 15),
            Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              readOnly: true,
              controller: TextEditingController(
                text: selectedTime != null
                    ? DateFormat('hh:mm a').format(DateTime(
                        2022, 1, 1, selectedTime!.hour, selectedTime!.minute))
                    : '',
              ),
              decoration: InputDecoration(
                hintText: 'Choose time',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
              ),
            ),
            SizedBox(height: 15),
            Text('Repeat', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedRepeat,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: ['No Repeat', 'Daily', 'Weekly', 'Monthly', 'Yearly']
                  .map((label) => DropdownMenuItem(
                        child: Text(label),
                        value: label,
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedRepeat = value!;
                });
              },
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.red)),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isSaveButtonEnabled ? _saveReminder : null,
                  child: Text('Save Reminder',
                      style: TextStyle(color: Colors.blue)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.blue, width: 2),
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

class EditReminderDialog extends StatefulWidget {
  final Map<String, dynamic> reminderData;
  final String docId;

  EditReminderDialog({required this.reminderData, required this.docId});

  @override
  _EditReminderDialogState createState() => _EditReminderDialogState();
}

class _EditReminderDialogState extends State<EditReminderDialog> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late String selectedRepeat;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.reminderData['title']);
    selectedDate = DateFormat('dd-MM-yyyy').parse(widget.reminderData['date']);
    selectedTime = TimeOfDay.fromDateTime(
        DateFormat('hh:mm a').parse(widget.reminderData['time']));
    selectedRepeat = widget.reminderData['repeat'];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _updateReminder() async {
    final updatedReminderData = {
      'title': _titleController.text,
      'date': DateFormat('dd-MM-yyyy').format(selectedDate),
      'time': DateFormat('hh:mm a')
          .format(DateTime(2022, 1, 1, selectedTime.hour, selectedTime.minute)),
      'repeat': selectedRepeat,
    };

    try {
      await FirebaseFirestore.instance
          .collection('reminders')
          .doc(widget.docId)
          .update(updatedReminderData);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder updated successfully')),
      );
    } catch (e) {
      print('Error updating reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reminder')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Reminder',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Eg. Water time',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 15),
            Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              readOnly: true,
              controller: TextEditingController(
                text: DateFormat('dd-MM-yyyy').format(selectedDate),
              ),
              decoration: InputDecoration(
                hintText: 'Choose calendar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
            ),
            SizedBox(height: 15),
            Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              readOnly: true,
              controller: TextEditingController(
                text: DateFormat('hh:mm a').format(DateTime(
                    2022, 1, 1, selectedTime.hour, selectedTime.minute)),
              ),
              decoration: InputDecoration(
                hintText: 'Choose time',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
              ),
            ),
            SizedBox(height: 15),
            Text('Repeat', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedRepeat,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: ['No Repeat', 'Daily', 'Weekly', 'Monthly', 'Yearly']
                  .map((label) => DropdownMenuItem(
                        child: Text(label),
                        value: label,
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedRepeat = value!;
                });
              },
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.red)),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _updateReminder,
                  child: Text('Update Reminder',
                      style: TextStyle(color: Colors.blue)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.blue, width: 2),
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
