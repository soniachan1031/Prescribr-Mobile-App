import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/top_bar.dart';
import '../utils/theme.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'add_screen.dart';
import 'zira_ai.dart';
import 'my_meds_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

//HomeScreenContent starts here
class HomeScreenContent extends StatelessWidget {
  final String greeting;
  final String firstName;
  final DateTime selectedDate;
  final VoidCallback onPreviousDate;
  final VoidCallback onNextDate;
  final List<Map<String, dynamic>> medications;
  final bool isLoading;
  final Function(Map<String, dynamic>) onTakeMedication;

  HomeScreenContent({
    required this.greeting,
    required this.firstName,
    required this.selectedDate,
    required this.onPreviousDate,
    required this.onNextDate,
    required this.medications,
    required this.isLoading,
    required this.onTakeMedication,
  });

  // Determine icon based on medication form
  IconData _getIconForForm(String form) {
    switch (form.toLowerCase()) {
      case 'tablet':
        return FontAwesomeIcons.tablets;
      case 'capsule':
        return FontAwesomeIcons.capsules;
      case 'liquid':
        return FontAwesomeIcons.droplet;
      case 'injection':
        return FontAwesomeIcons.syringe;
      case 'inhaler':
        return FontAwesomeIcons.heartPulse;
      default:
        return FontAwesomeIcons.pills; // Default icon
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    // Group medications by time
    final Map<String, List<Map<String, dynamic>>> groupedMedications = {};
    for (var med in medications) {
      final String timeKey = timeFormat.format(med['time']);
      if (!groupedMedications.containsKey(timeKey)) {
        groupedMedications[timeKey] = [];
      }
      groupedMedications[timeKey]!.add(med);
    }

    // Sort the time keys for display
    final sortedTimeKeys = groupedMedications.keys.toList()
      ..sort((a, b) => timeFormat.parse(a).compareTo(timeFormat.parse(b)));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Text
            Text(
              '$greeting, $firstName!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.blackColor,
                  ),
            ),
            const SizedBox(height: 24.0),

            // Date Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: onPreviousDate,
                  color: AppTheme.blackColor,
                ),
                Text(
                  dateFormat.format(selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 28),
                  onPressed: onNextDate,
                  color: AppTheme.blackColor,
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Loader
            if (isLoading)
              Center(
                child: Column(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.spinner,
                      size: 24.0, // Adjust size
                      color: AppTheme.greyColor, // Adjust color
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Loading your medications...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              )

            // No Reminders Message
            else if (medications.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'No reminders for this day.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                    ),
                  ],
                ),
              )

            // Display Reminders by Grouped Time
            else
              ...sortedTimeKeys.map((timeKey) {
                final meds = groupedMedications[timeKey]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time Header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          timeKey,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.blackColor,
                                  ),
                        ),
                      ),
                      SizedBox(height: 12.0),

                      // Medications for the time
                      ...meds.map((med) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor,
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: FaIcon(
                              _getIconForForm(med['form']),
                              size: 24,
                              color: AppTheme.mediumLightIconColor,
                            ),
                            title: Text(
                              med['name'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                            ),
                            subtitle: Text(
                              'Take: ${med['quantity']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => onTakeMedication(med),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: const Text(
                                'Take',
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  String _greeting = '';
  String _firstName = '';
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _setGreeting();
    _checkLoginStatus();
    _fetchUserProfile();
    _fetchMedications();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      _greeting = 'Good morning';
    } else if (hour >= 12 && hour < 18) {
      _greeting = 'Good afternoon';
    } else if (hour >= 18 && hour < 21) {
      _greeting = 'Good evening';
    } else {
      _greeting = 'Good night';
    }
  }

  Future<void> _checkLoginStatus() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Navigate to LoginScreen and wait for result
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );

        // Refresh HomeScreen if login was successful
        if (result == true) {
          _fetchUserProfile();
          _fetchMedications();
          print("Navigating to LoginScreen...");
          print("Login result: $result");
          print("Refreshing HomeScreen...");
          setState(() {}); // Trigger a rebuild
        }
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return; // Prevent setState if widget is unmounted

      setState(() {
        _firstName = userDoc['firstName'] ?? 'User';
      });
    }
  }

  Future<void> _fetchMedications() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot medicationsSnapshot = await FirebaseFirestore.instance
          .collection('medications')
          .doc(user.uid)
          .collection('userMedications')
          .get();

      final List<Map<String, dynamic>> remindersForDay = [];
      final DateTime startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      print("Fetching medications for selected date: $_selectedDate");

      for (var doc in medicationsSnapshot.docs) {
        final medicationData = doc.data() as Map<String, dynamic>?;
        if (medicationData == null) continue;

        print("Medication: ${medicationData['drugName']}");

        final String drugName = medicationData['drugName'] ?? 'Unknown';
        final String pills = medicationData['pills'] ?? 'Unknown';
        final String form = medicationData['form'] ?? '';
        final DateTime startDate = DateTime.parse(medicationData['startDate']);
        final DateTime endDate = DateTime.parse(medicationData['endDate']);

        // Skip if the selected date is outside the medication's active range
        if (_selectedDate.isBefore(startDate) ||
            _selectedDate.isAfter(endDate)) {
          print("Skipping ${medicationData['drugName']} - outside date range.");
          continue;
        }

        // Fetch reminders
        final QuerySnapshot remindersSnapshot =
            await doc.reference.collection('reminders').get();

        for (var reminderDoc in remindersSnapshot.docs) {
          final reminderData = reminderDoc.data() as Map<String, dynamic>?;
          if (reminderData == null) continue;

          print("Processing reminder: $reminderData");

          // Skip reminders that are already marked as "taken"
          if (reminderData['taken'] == true) {
            print(
                "Skipping taken reminder for ${medicationData['drugName']} at ${reminderData['time']}.");
            continue;
          }

          final DateTime reminderTime = DateTime.parse(reminderData['time']);
          final String frequency = reminderData['frequency'] ?? 'Daily';

          // Frequency logic (Daily or Every X days)
          bool shouldAddReminder = false;
          if (frequency == 'Daily') {
            shouldAddReminder = true;
          } else if (frequency.startsWith('Every')) {
            final int intervalDays = int.parse(
                frequency.split(' ')[1]); // Get the interval (e.g., 2 days)
            final int daysSinceStart =
                _selectedDate.difference(startDate).inDays;

            // Check if the current date aligns with the frequency interval
            if (daysSinceStart >= 0 && daysSinceStart % intervalDays == 0) {
              shouldAddReminder = true;
            }
          }

          // Add reminder only if the frequency aligns
          if (shouldAddReminder) {
            final DateTime scheduledTime = DateTime(
              startOfDay.year,
              startOfDay.month,
              startOfDay.day,
              reminderTime.hour,
              reminderTime.minute,
            );

            // Check for duplicates
            if (!remindersForDay.any((reminder) =>
                reminder['name'] == drugName &&
                reminder['time'] == scheduledTime)) {
              remindersForDay.add({
                'name': drugName,
                'quantity': pills,
                'form': form,
                'time': scheduledTime,
              });

              print("Added reminder for $drugName at $scheduledTime");
            } else {
              print(
                  "Duplicate reminder for $drugName at $scheduledTime skipped.");
            }
          }
        }
      }

      setState(() {
        _medications = remindersForDay;
        _isLoading = false;
      });

      print("Reminders for selected day: $_medications");
    } catch (e) {
      print("Error fetching medications: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load medications: $e")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTakeMedication(Map<String, dynamic> medication) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Access the medications collection
      final medicationsCollection = FirebaseFirestore.instance
          .collection('medications')
          .doc(user.uid)
          .collection('userMedications');

      // Query the medication document by drug name
      final medicationQuery = await medicationsCollection
          .where('drugName', isEqualTo: medication['name'])
          .get();

      if (medicationQuery.docs.isNotEmpty) {
        final medicationDoc = medicationQuery.docs.first;

        // Query the specific reminder by time
        final remindersCollection =
            medicationDoc.reference.collection('reminders');
        final reminderQuery = await remindersCollection
            .where('time', isEqualTo: medication['time'].toIso8601String())
            .get();

        if (reminderQuery.docs.isNotEmpty) {
          final reminderDoc = reminderQuery.docs.first;

          // Update the reminder to mark it as taken
          await reminderDoc.reference.update({'taken': true});

          print(
              "Reminder for ${medication['name']} at ${medication['time']} marked as taken in Firestore.");
        } else {
          print(
              "No matching reminder found in Firestore for ${medication['name']} at ${medication['time']}.");
        }
      } else {
        print(
            "No matching medication found in Firestore for ${medication['name']}.");
      }

      // Update the local list to remove the medication
      setState(() {
        _medications.remove(medication);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${medication['name']} taken successfully!')),
      );
    } catch (e) {
      print("Error marking medication as taken: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark medication as taken: $e')),
      );
    }
  }

// Helper method to parse time strings (e.g., "4:12 PM")
  TimeOfDay _parseTime(String time) {
    final format = DateFormat.jm(); // "4:12 PM"
    final DateTime dateTime = format.parse(time);
    return TimeOfDay.fromDateTime(dateTime);
  }

  void _previousDate() {
    setState(() {
      _selectedDate = _selectedDate.subtract(Duration(days: 1));
      _fetchMedications();
    });
  }

  void _nextDate() {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: 1));
      _fetchMedications();
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreenContent(
          greeting: _greeting,
          firstName: _firstName,
          selectedDate: _selectedDate,
          onPreviousDate: _previousDate,
          onNextDate: _nextDate,
          medications: _medications,
          isLoading: _isLoading,
          onTakeMedication: _onTakeMedication,
        );
      case 1:
        return AddScreen();
      case 2:
        return MyMedsScreen();
      case 3:
        return ZiraAIScreen();
      case 4:
        return ProfileScreen();
      default:
        return HomeScreenContent(
          greeting: _greeting,
          firstName: _firstName,
          selectedDate: _selectedDate,
          onPreviousDate: _previousDate,
          onNextDate: _nextDate,
          medications: _medications,
          isLoading: _isLoading,
          onTakeMedication: _onTakeMedication,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        showBackButton: _selectedIndex != 0,
        onBack: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      ),
      body: _getScreen(_selectedIndex),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _selectedIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}
