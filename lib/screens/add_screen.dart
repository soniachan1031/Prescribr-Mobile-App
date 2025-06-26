import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_screen.dart';
import '../utils/notification_helper.dart';
import '../utils/theme.dart';

// AddScreen starts here
class AddScreen extends StatefulWidget {
  final Map<String, dynamic>? medication;

  const AddScreen({Key? key, this.medication}) : super(key: key);

  @override
  _AddScreenState createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final TextEditingController drugNameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedForm;
  String _quantityLabel = 'How many pills?';

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      drugNameController.text = widget.medication!['name'] ?? '';
      dosageController.text = widget.medication!['dosage'] ?? '';
      quantityController.text = widget.medication!['quantity'] ?? '';
      _selectedForm = widget.medication!['form'];
      _updateQuantityLabel();
    }
  }

  @override
  void dispose() {
    drugNameController.dispose();
    dosageController.dispose();
    quantityController.dispose();
    endDateController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _updateQuantityLabel() {
    setState(() {
      _quantityLabel = 'How many ${_selectedForm?.toLowerCase() ?? 'pills'}?';
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        endDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8.0),
            // Form Fields
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medication Name
                  TextFormField(
                    controller: drugNameController,
                    decoration: InputDecoration(
                      labelText: 'Medication Name',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 10.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the medication name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Medication Form Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedForm,
                    decoration: InputDecoration(
                      labelText: 'Medication Form',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 10.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      'Tablet',
                      'Capsule',
                      'Liquid',
                      'Injection',
                      'Inhaler',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedForm = newValue;
                        _updateQuantityLabel();
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select the medication form';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Dosage Field
                  TextFormField(
                    controller: dosageController,
                    decoration: InputDecoration(
                      labelText: 'Dosage (optional)',
                      hintText: 'e.g., 500 mg',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 10.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Quantity Field
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _quantityLabel,
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 10.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30.0),

                  // Advanced Settings Header
                  Text(
                    'Advanced Settings',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blackColor,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16.0),

                  // End Date
                  TextFormField(
                    controller: endDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'End Date (optional)',
                      hintText: 'Select end date',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 10.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16.0),

                  // Notes
                  TextFormField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Additional Note (optional)',
                      hintText: 'e.g., Take with food',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 10.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30.0),

                  // Next Button
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScheduleScreen(
                                drugName: drugNameController.text,
                                dosage: dosageController.text,
                                pills: quantityController.text,
                                form: _selectedForm!,
                                endDate: endDateController.text,
                                note: noteController.text,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 30.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ScheduleScreen starts here
class ScheduleScreen extends StatefulWidget {
  final String drugName;
  final String dosage;
  final String pills;
  final String form;
  final String endDate;
  final String note;

  const ScheduleScreen({
    Key? key,
    required this.drugName,
    required this.dosage,
    required this.pills,
    required this.form,
    required this.endDate,
    required this.note,
  }) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TextEditingController timeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedFrequency;
  final List<Map<String, String>> _schedules = [];
  int? _editingIndex;
  static const int maxSchedules = 4;

  @override
  void dispose() {
    timeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        timeController.text = picked.format(context);
      });
    }
  }

  void _showAddPopup(BuildContext context, {int? index}) {
    if (index != null) {
      timeController.text = _schedules[index]['time']!;
      _selectedFrequency = _schedules[index]['frequency'];
      _editingIndex = index;
    } else {
      timeController.clear();
      _selectedFrequency = null;
      _editingIndex = null;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: AppTheme.whiteColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  index == null ? 'Add Schedule' : 'Edit Schedule',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),

                // Form Content
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Time Input
                      TextFormField(
                        controller: timeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Time',
                          hintText: 'e.g. 8:00 AM',
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14.0,
                            horizontal: 10.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onTap: () => _selectTime(context),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the time';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Frequency Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedFrequency,
                        decoration: InputDecoration(
                          labelText: 'Frequency',
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14.0,
                            horizontal: 10.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          '1 min',
                          'Daily',
                          'Every 2 days',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedFrequency = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select the frequency';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10.0),

                    // Add/Save Button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              if (_editingIndex != null) {
                                _schedules[_editingIndex!] = {
                                  'time': timeController.text,
                                  'frequency': _selectedFrequency!,
                                };
                              } else {
                                _schedules.add({
                                  'time': timeController.text,
                                  'frequency': _selectedFrequency!,
                                });
                              }
                            });
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(index == null ? 'Add' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Medication'),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8.0),
            // Schedule List
            Expanded(
              child: _schedules.isEmpty
                  ? Center(
                child: Text(
                  'No schedules added. Tap "+" to add a new schedule.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  final schedule = _schedules[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    color: Colors.grey[100], // Updated card color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // FontAwesome Clock Icon
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.clock,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12.0),

                          // Schedule Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time: ${schedule['time']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  'Frequency: ${schedule['frequency']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Edit/Delete Icons
                          Row(
                            children: [
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.penToSquare,
                                  color: AppTheme.greyColor,
                                ),
                                onPressed: () =>
                                    _showAddPopup(context, index: index),
                              ),
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.trash,
                                  color: AppTheme.redColor,
                                ),
                                onPressed: () => _deleteSchedule(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Previous and Next Buttons
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Previous Button
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child:

                Text(
                  'Previous',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 10.0),

            // Next Button
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
                onPressed: _schedules.isNotEmpty
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConfirmScreen(
                        drugName: widget.drugName,
                        dosage: widget.dosage,
                        pills: widget.pills,
                        form: widget.form,
                        schedules: _schedules,
                        endDate: widget.endDate,
                        note: widget.note,
                      ),
                    ),
                  );
                }
                    : null,
                label: const Text('Next'),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _schedules.length < maxSchedules
            ? () => _showAddPopup(context)
            : null,
        backgroundColor: _schedules.length < maxSchedules
            ? Theme.of(context).primaryColor
            : Colors.grey, // Disabled color
        elevation: _schedules.length < maxSchedules ? 6 : 0, // No shadow when disabled
        child: const FaIcon(FontAwesomeIcons.plus),
      ),
    );
  }
}

// ConfirmScreen starts here
class ConfirmScreen extends StatefulWidget {
  final String drugName;
  final String dosage;
  final String pills;
  final String form;
  final List<Map<String, String>> schedules;
  final String? endDate;
  final String? note;

  const ConfirmScreen({
    Key? key,
    required this.drugName,
    required this.dosage,
    required this.pills,
    required this.form,
    required this.schedules,
    this.endDate,
    this.note,
  }) : super(key: key);

  @override
  _ConfirmScreenState createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  bool _isSaving = false; // State variable to track saving progress

  Future<void> _saveToDatabase(BuildContext context) async {
    setState(() {
      _isSaving = true; // Start saving
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isSaving = false; // Reset saving state
      });
      print("Error: User not logged in.");
      return;
    }

    try {
      final CollectionReference medications = FirebaseFirestore.instance
          .collection('medications')
          .doc(user.uid)
          .collection('userMedications');

      final DateTime now = DateTime.now();
      final DateTime endDate = widget.endDate != null && widget.endDate!.isNotEmpty
          ? DateTime.parse(widget.endDate!)
          : now.add(const Duration(days: 365 * 2));

      // Save the main medication document
      final DocumentReference medicationRef = await medications.add({
        'drugName': widget.drugName,
        'dosage': widget.dosage,
        'pills': widget.pills,
        'form': widget.form,
        'startDate': now.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'note': widget.note,
      });

      print("Medication document added with ID: ${medicationRef.id}");

      for (var schedule in widget.schedules) {
        final String time = schedule['time'] ?? '12:00 AM';
        final String frequency = schedule['frequency'] ?? '1 min';

        print("Processing schedule: $schedule");

        // Parse user-selected time
        final TimeOfDay parsedTime = TimeOfDay(
          hour: int.parse(time.split(":")[0]),
          minute: int.parse(time.split(":")[1].split(" ")[0]),
        );

        DateTime scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          parsedTime.hour,
          parsedTime.minute,
        );

        if (scheduledDateTime.isBefore(now)) {
          scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
        }

        print("First scheduled time: $scheduledDateTime");

        if (frequency == '1 min') {
          for (int i = 0; i < 10; i++) {
            DateTime notificationTime = scheduledDateTime.add(Duration(minutes: i));
            print("Scheduling notification for 1 min at: $notificationTime");

            await NotificationHelper.showNotification(
              'Medication Reminder',
              'Time to take ${widget.drugName} (${widget.dosage})',
              notificationTime,
            );

            await medicationRef.collection('reminders').add({
              'time': notificationTime.toIso8601String(),
              'frequency': '1 min',
              'startDate': now.toIso8601String(),
              'endDate': endDate.toIso8601String(),
            });
          }
        } else if (frequency == 'Daily') {
          for (int i = 0; i < 20; i++) {
            DateTime notificationTime = scheduledDateTime.add(Duration(days: i));
            print("Scheduling daily notification at: $notificationTime");

            await NotificationHelper.showNotification(
              'Medication Reminder',
              'Time to take ${widget.drugName} (${widget.dosage})',
              notificationTime,
            );

            await medicationRef.collection('reminders').add({
              'time': notificationTime.toIso8601String(),
              'frequency': 'Daily',
              'startDate': now.toIso8601String(),
              'endDate': endDate.toIso8601String(),
            });
          }
        } else if (frequency == 'Every 2 days') {
          for (int i = 0; i < 20; i++) {
            DateTime notificationTime = scheduledDateTime.add(Duration(days: i * 2));
            print("Scheduling every 2 days notification at: $notificationTime");

            await NotificationHelper.showNotification(
              'Medication Reminder',
              'Time to take ${widget.drugName} (${widget.dosage})',
              notificationTime,
            );

            await medicationRef.collection('reminders').add({
              'time': notificationTime.toIso8601String(),
              'frequency': 'Every 2 days',
              'startDate': now.toIso8601String(),
              'endDate': endDate.toIso8601String(),
            });
          }
        }
      }

      print("All schedules processed successfully.");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(initialIndex: 2),
        ),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Error saving data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save medication: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false; // Reset saving state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Medication'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              Text(
                "Review and Confirm",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20.0),

              // Medication Details Card
              Card(
                color: Colors.grey[50],
                elevation: 3.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow("Drug Name", widget.drugName),
                      if (widget.dosage.isNotEmpty)
                        _buildDetailRow("Dosage", widget.dosage),
                      _buildDetailRow("Quantity", widget.pills),
                      _buildDetailRow("Form", widget.form),
                      const SizedBox(height: 20.0),
                      Text(
                        "Schedules",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      ...widget.schedules.map(
                            (schedule) => _buildScheduleCard(schedule, context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30.0),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: !_isSaving
                          ? () {
                        Navigator.pop(context);
                      }
                          : null,
                      child: Text(
                        'Previous',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !_isSaving ? () => _saveToDatabase(context) : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, String> schedule, BuildContext context) {
    return Card(
      color: AppTheme.whiteColor,
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: Theme.of(context).primaryColor,
              size: 28.0,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time: ${schedule['time']}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Frequency: ${schedule['frequency']}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}