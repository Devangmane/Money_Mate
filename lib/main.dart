import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this for Clipboard functionality
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moneymate/firebase_options.dart';
import 'package:moneymate/login_page.dart';  // Import the login page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'MoneyMate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home:const AuthPage() //MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  String _text = '';
  String _totalPrice = '';
  String _date = '';
  String _sellerName = '';

  // Initialize with the first value in the dropdown list
  String _expenseType = 'Rent';
  String _paymentMethod = 'UPI';

  late final  ImagePicker _picker = ImagePicker();
  late final  TextRecognizer _textRecognizer = TextRecognizer();

  late final TextEditingController _totalPriceController = TextEditingController();
  late final TextEditingController _sellerNameController = TextEditingController();
  late final TextEditingController _dateController = TextEditingController();



  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _scanText();
    }
  }

  Future<void> _scanText() async {
    if (_image != null) {
      final inputImage = InputImage.fromFilePath(_image!.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      final pricePattern = RegExp(r'(total|amount|subtotal|grand total)\s*:?\s*\$?(\d+[.,]?\d*)', caseSensitive: false);
      final datePattern = RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b');
      final sellerPattern = RegExp(r'(seller|store|merchant|invoice to|from)\s*:\s*(.+)', caseSensitive: false);

      String totalPrice = '';
      String date = '';
      String sellerName = '';

      print("Recognized Text:");
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String lineText = line.text.toLowerCase();
          print(lineText);

          if (pricePattern.hasMatch(lineText) && totalPrice.isEmpty) {
            totalPrice = pricePattern.firstMatch(lineText)!.group(2) ?? '';
          }

          if (datePattern.hasMatch(lineText) && date.isEmpty) {
            date = datePattern.firstMatch(lineText)!.group(0) ?? '';
          }

          if (sellerPattern.hasMatch(lineText) && sellerName.isEmpty) {
            sellerName = sellerPattern.firstMatch(lineText)!.group(2) ?? '';
          }
        }
      }

      setState(() {
        _totalPrice = totalPrice;
        _date = date;
        _sellerName = sellerName;
        _text = 'Seller: $sellerName\nDate: $date\nTotal: $totalPrice';

        _totalPriceController.text = totalPrice;
        _dateController.text = date;
        _sellerNameController.text = sellerName;
      });
    }
  }

  void _copyToClipboard() {
    if (_text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard')),
      );
    }
  }

  void _updateInfo() {
    setState(() {
      _totalPrice = _totalPriceController.text;
      _date = _dateController.text;
      _sellerName = _sellerNameController.text;
      _text = 'Seller: $_sellerName\nDate: $_date\nTotal: $_totalPrice';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to Text'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PastExpensesScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _image != null
                  ? Image.file(_image!)
                  : const Text('No image selected.'),
              const SizedBox(height: 20),
              _buildInfoBox('Seller Name:', _sellerNameController),
              _buildInfoBox('Date:', _dateController),
              _buildInfoBox('Total Price:', _totalPriceController),
              const SizedBox(height: 20),
              _buildDropdown(
                'Type of Expense:',
                ['Rent', 'Clothing', 'Travel', 'Groceries', 'Utilities', 'Dining', 'Entertainment', 'Education', 'Healthcare', 'Transportation', 'Personal Care', 'Fitness', 'Mobile', 'Internet', 'Subscriptions', 'Miscellaneous'],
                _expenseType,
                    (newValue) {
                  setState(() {
                    _expenseType = newValue!;
                  });
                },
              ),
              _buildDropdown(
                'Payment Method:',
                ['UPI', 'Cash', 'Netbanking'],
                _paymentMethod,
                    (newValue) {
                  setState(() {
                    _paymentMethod = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateInfo,
                child: const Text('Update Info'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveDataToFirestore,
                child: const Text('Save to Firestore'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _pickImage(ImageSource.camera),
            tooltip: 'Capture Image',
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            tooltip: 'Upload from Gallery',
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter $label',
              ),
              onChanged: (value) => _updateInfo(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDataToFirestore() async {
    try {
      print("Starting to store");
      // Create a map with the data to store
      Map<String, dynamic> data = {
        'totalPrice': _totalPrice,
        'date': _date,
        'sellerName': _sellerName,
        'expenseType': _expenseType,
        'paymentMethod': _paymentMethod,
        'timestamp': FieldValue.serverTimestamp(),  // Optional: add a timestamp
      };
      print("Map Generated");
      // Save the data to a 'expenses' collection
      await FirebaseFirestore.instance.collection('Users').doc(FirebaseAuth.instance.currentUser!.uid).collection("expenses").add(data);
      print("saved to database");
      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data saved to Firestore')),
      );
    } catch (e) {
      print("Failed to save data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    }
  }


  Widget _buildDropdown(
      String label,
      List<String> items,
      String selectedValue,
      void Function(String?) onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: onChanged,
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
class PastExpensesScreen extends StatelessWidget {
  const PastExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Expenses'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection("expenses")
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No past expenses found.'));
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
    );
  }
}
