import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateInfoPage extends StatefulWidget {
  const UpdateInfoPage({super.key});

  @override
  _UpdateInfoPageState createState() => _UpdateInfoPageState();
}

class _UpdateInfoPageState extends State<UpdateInfoPage> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String age = '';
  String gender = '';
  String contactNumber = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Your Info'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'First Name',
                    icon: Icons.person,
                    onChanged: (value) => setState(() => firstName = value),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'Last Name',
                    icon: Icons.person_outline,
                    onChanged: (value) => setState(() => lastName = value),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'Age',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => age = value),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'Gender',
                    icon: Icons.wc,
                    onChanged: (value) => setState(() => gender = value),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    label: 'Contact Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    onChanged: (value) => setState(() => contactNumber = value),
                  ),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          setState(() {
            isLoading = true;
          });
          try {
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .set({
              'firstName': firstName,
              'lastName': lastName,
              'age': age,
              'gender': gender,
              'contactNumber': contactNumber,
            }, SetOptions(merge: true));

            setState(() {
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Information updated successfully!')),
            );
          } catch (e) {
            setState(() {
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update information: $e')),
            );
          }
        }
      },
      child: const Text(
        'Update Info',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
