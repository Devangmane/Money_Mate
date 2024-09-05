import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'package:moneymate/about_us_page.dart';
import 'package:moneymate/update_info_page.dart';


class PostLoginPage extends StatefulWidget {
  const PostLoginPage({super.key});

  @override
  State<PostLoginPage> createState() => _PostLoginPageState();
}

class _PostLoginPageState extends State<PostLoginPage> {
  String? firstName;

  @override
  void initState() {
    super.initState();
    fetchUserFirstName();
  }

  // Fetch the user's first name from Firestore
  Future<void> fetchUserFirstName() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      setState(() {
        firstName = userDoc['firstName'] ?? 'User'; // Fallback if first name is not found
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching user first name: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    String todayDate = DateFormat.yMMMMd().format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      // Drawer section
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Date: $todayDate',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hi ${firstName ?? 'User'}', // Display user's first name
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('About Us'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutUsPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Update Your Info'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpdateInfoPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Close'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Button section
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the MyHomePage (the page with the image-to-text functionality)
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyHomePage()),
                      );
                    },
                    child: const Text('Add New Transaction'),
                  ),
                  const SizedBox(height: 20), // Add some space between the buttons
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the PastExpensesScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PastExpensesScreen()),
                      );
                    },
                    child: const Text('Show All Past Expenses'),
                  ),
                ],
              ),
            ),
          ),
          // Recent expenses section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Recent Expenses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection("expenses")
                        .orderBy('timestamp', descending: true)
                        .limit(5) // Limit to 5 recent transactions
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No recent transactions found.'));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var expense = snapshot.data!.docs[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text('${expense['sellerName']} - ${expense['totalPrice']}'),
                              subtitle: Text('${expense['date']} - ${expense['expenseType']}'),
                              trailing: Text(expense['paymentMethod']),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

