import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SetMonthlyIncomePage extends StatefulWidget {
  const SetMonthlyIncomePage({Key? key}) : super(key: key);

  @override
  _SetMonthlyIncomePageState createState() => _SetMonthlyIncomePageState();
}

class _SetMonthlyIncomePageState extends State<SetMonthlyIncomePage> {
  final TextEditingController _incomeController = TextEditingController();

  Future<void> setMonthlyIncome() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final income = double.tryParse(_incomeController.text);

      if (income != null) {
        await FirebaseFirestore.instance.collection('Users').doc(userId).update({
          'monthlyIncome': income,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Monthly income set to ₹$income')),
        );

        Navigator.pop(context); // Go back to the previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid income')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Monthly Income'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _incomeController,
              decoration: const InputDecoration(labelText: 'Enter Monthly Income (₹)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: setMonthlyIncome,
              child: const Text('Set Monthly Income'),
            ),
          ],
        ),
      ),
    );
  }
}
