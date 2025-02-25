import 'package:flutter/material.dart';
import 'package:se380_project/PageOne.dart';
import 'package:se380_project/PageTwo.dart';
import 'package:se380_project/PageThree.dart';
import 'package:se380_project/PageFour.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';

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
      home: const MyHomePage(title: 'Vocab Quiz Game'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int pageIndex = 0;
  static late String userId;
  static bool determineUserId=false;

  @override
  void initState() {
    initializeUserId();
    super.initState();
  }



  final List<Widget> _pages = [
    const PageOne(),
    const PageTwo(),
    const PageThree(),
    const PageFour(),
  ];


  Future <void> initializeUserId()async {
    await SharedPreferences.getInstance().then((prefs){
      setState(() {
        userId= prefs.getString('UserId')?? "";
        print("myUSerID");
        print(userId);
      });
      return prefs;
    }).then((prefs)async{
      if(userId==""){
        setState(() {
          determineUserId=true;
        });
      }
    });



  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              icon: Icon(Icons.sort),
              label: 'Rankings',
            )
          ]),
    );
  }
}
