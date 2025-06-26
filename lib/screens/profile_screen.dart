import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_screen.dart';
import '../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _saveProfile() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'phone': _phoneController.text,
          'dob': _dobController.text,
          'height': _heightController.text,
          'weight': _weightController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'province': _provinceController.text,
          'zipCode': _zipCodeController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile: $e")),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _firstNameController.text = userData['firstName'] ?? '';
            _lastNameController.text = userData['lastName'] ?? '';
            _emailController.text = user.email ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _dobController.text = userData['dob'] ?? '';
            _heightController.text = userData['height'] ?? '';
            _weightController.text = userData['weight'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _cityController.text = userData['city'] ?? '';
            _provinceController.text = userData['province'] ?? '';
            _zipCodeController.text = userData['zipCode'] ?? '';
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("User data not found")),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load user data: $e")),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _logout() async {
    print('🔵 Logout: Signing out user');
    await _auth.signOut();
    // First await the authStateChanges to propagate
    await FirebaseAuth.instance.authStateChanges().first;
    print('🔵 Logout: Auth state updated after signOut');
    // Then use root navigator for consistent navigation approach
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteProfile() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final QuerySnapshot medicationsSnapshot = await _firestore
            .collection('medications')
            .doc(user.uid)
            .collection('userMedications')
            .get();
        for (final DocumentSnapshot doc in medicationsSnapshot.docs) {
          await doc.reference.delete();
        }

        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile deleted successfully")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete profile: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
            tooltip: 'Logout',
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.redColor,
                          foregroundColor: AppTheme.whiteColor,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                _logout();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: FaIcon(FontAwesomeIcons.spinner, size: 40),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: const FaIcon(
                FontAwesomeIcons.user,
                size: 40,
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hello ${_firstNameController.text} ${_lastNameController.text}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Editable Fields
            _buildEditableField('First Name', _firstNameController),
            _buildEditableField('Last Name', _lastNameController),
            _buildEditableField('Email', _emailController, readOnly: true),
            _buildEditableField('Phone Number (optional)', _phoneController),
            _buildEditableField(
              'Date of Birth',
              _dobController,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            _buildEditableField('Height (cm)', _heightController),
            _buildEditableField('Weight (kg)', _weightController),
            _buildEditableField('Home Address', _addressController),
            _buildEditableField('City', _cityController),
            _buildEditableField('Province', _provinceController),
            _buildEditableField('Zip Code', _zipCodeController),

            const SizedBox(height: 20.0),

            // Save Profile Button
            ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const FaIcon(FontAwesomeIcons.floppyDisk, size: 18),
              label: const Text(
                'Save Profile',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 30.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Delete Profile Button
            ElevatedButton.icon(
              onPressed: () async {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      title: const Text(
                        'Delete Profile',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        'Are you sure you want to delete your profile? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  _deleteProfile();
                }
              },
              icon: const FaIcon(FontAwesomeIcons.trashCan, size: 18),
              label: const Text(
                'Delete My Profile',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 30.0),
                backgroundColor: AppTheme.redColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller,
      {bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 16.0,),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
    style: const TextStyle(
    fontSize: 16.0, // Adjust for font size consistency
    height: 1.5,
    ),
      ),
    );
  }
}