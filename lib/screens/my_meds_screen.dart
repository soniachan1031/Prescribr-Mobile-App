import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';

class MyMedsScreen extends StatefulWidget {
  const MyMedsScreen({super.key});
  @override
  _MyMedsScreenState createState() => _MyMedsScreenState();
}

class _MyMedsScreenState extends State<MyMedsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  Future<void> _fetchMedications() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot medicationsSnapshot = await _firestore
          .collection('medications')
          .doc(user.uid)
          .collection('userMedications')
          .get();

      final List<Map<String, dynamic>> medications = [];

      for (var doc in medicationsSnapshot.docs) {
        final medicationData = doc.data() as Map<String, dynamic>?;

        if (medicationData == null) continue;

        final String drugName = medicationData['drugName'] ?? 'Unknown';
        final String pills = medicationData['pills'] ?? 'Unknown';
        final String form = medicationData['form'] ?? '';
        final String dosage = medicationData['dosage'] ?? '';
        final String note = medicationData['note'] ?? '';
        final DateTime startDate = DateTime.parse(medicationData['startDate']);
        final DateTime endDate = DateTime.parse(medicationData['endDate']);

        // Fetch reminders
        final QuerySnapshot remindersSnapshot =
        await doc.reference.collection('reminders').get();

        final List<Map<String, dynamic>> reminders = remindersSnapshot.docs
            .map((reminderDoc) {
          final reminderData = reminderDoc.data() as Map<String, dynamic>?;
          if (reminderData == null) return null;

          return {
            'time': reminderData['time'],
            'frequency': reminderData['frequency'] ?? 'Daily',
            'startDate': reminderData['startDate'],
            'endDate': reminderData['endDate'],
          };
        })
            .where((reminder) => reminder != null)
            .toList()
            .cast<Map<String, dynamic>>();

        medications.add({
          'id': doc.id,
          'drugName': drugName,
          'pills': pills,
          'form': form,
          'dosage': dosage,
          'note': note,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'reminders': reminders,
        });
      }

      setState(() {
        _medications = medications;
        _isLoading = false;
      });
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

  void _deleteMedication(Map<String, dynamic> med) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('medications')
            .doc(user.uid)
            .collection('userMedications')
            .doc(med['id'])
            .delete();
        setState(() {
          _medications.remove(med);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Medication deleted successfully")),
        );
      } catch (e) {
        print("Error deleting medication: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete medication: $e")),
        );
      }
    }
  }

  void _confirmDeleteMedication(Map<String, dynamic> med) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this medication?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMedication(med);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _showDetailsPopup(Map<String, dynamic> med) {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        med['drugName'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.times, size: 18),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const Divider(),

                // Scrollable Content Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Take', med['pills'], context),
                        _buildDetailRow('Form', med['form'], context),
                        if (med['dosage'].isNotEmpty) _buildDetailRow('Dosage', med['dosage'], context),
                        _buildDetailRow('Start Date', dateFormat.format(DateTime.parse(med['startDate'])), context),
                        _buildDetailRow('End Date', dateFormat.format(DateTime.parse(med['endDate'])), context),
                        if (med['note'].isNotEmpty) _buildDetailRow('Note', med['note'], context),
                        const SizedBox(height: 16),
                        Text(
                          'Reminders',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...med['reminders'].map<Widget>((reminder) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.clock,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Time: ${dateFormat.format(DateTime.parse(reminder['time']))}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: _isLoading
          ? Center(
        child: FaIcon(
          FontAwesomeIcons.spinner,
          size: 64,
          color: AppTheme.greyColor,
        ),
      )
          : _medications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.pills,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'You have no medications added',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _medications.map((med) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: FaIcon(
                  _getMedicationIcon(med['form']),
                  size: 24,
                  color: AppTheme.mediumLightIconColor,
                ),
                title: Text(
                  med['drugName'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'Take: ${med['pills']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.eye,
                        color: AppTheme.greyColor,
                      ),
                      onPressed: () {
                        _showDetailsPopup(med);
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.trash,
                        color: AppTheme.redColor,
                      ),
                      onPressed: () {
                        _confirmDeleteMedication(med);
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Helper method to get appropriate FontAwesome icon for the medication form
  IconData _getMedicationIcon(String form) {
    switch (form.toLowerCase()) {
      case 'tablet':
        return FontAwesomeIcons.tablets;
      case 'capsule':
        return FontAwesomeIcons.capsules;
      case 'liquid':
        return FontAwesomeIcons.flask;
      case 'injection':
        return FontAwesomeIcons.syringe;
      case 'inhaler':
        return FontAwesomeIcons.lungs;
      default:
        return FontAwesomeIcons.pills; // Default icon
    }
  }
}
