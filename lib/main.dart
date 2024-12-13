import 'package:flutter/material.dart';
import 'package:se380_project/PageOne.dart';
import 'package:se380_project/PageTwo.dart';
import 'package:se380_project/PageThree.dart';
import 'package:se380_project/PageFour.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // CLI ile oluşturulmuş dosya

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Title'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int pageIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addData() async {
    for (int i = 0; i < 2; i++) {
      try {
        await _firestore.collection('users').doc('exampleUser$i').set({
          'name': 'ömer gök',
          'age': 30,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Data added successfully for exampleUser$i!');
      } catch (e) {
        print('Failed to add data for exampleUser$i: $e');
      }
    }
  }

  @override
  void initState() {
    _addData();
    super.initState();
  }

  final List<Widget> _pages = [
    const PageOne(),
    const PageTwo(),
    const PageThree(),
    const PageFour(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 174, 133, 231),
        title: Center(
          child: Text(
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            widget.title,
          ),
        ),
      ),
      body: _pages[pageIndex],
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: pageIndex,
          onTap: (index) {
            setState(() {
              pageIndex = index;
            });
          },
          selectedItemColor: const Color.fromARGB(255, 224, 143, 242),
          unselectedItemColor: const Color.fromARGB(255, 226, 179, 237),
          selectedLabelStyle:
              TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home Page'),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book), label: 'Tests'),
            BottomNavigationBarItem(
                icon: Icon(Icons.insights), label: 'Statistics'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            )
          ]),
    );
  }
}
