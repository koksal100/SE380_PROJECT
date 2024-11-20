import 'package:flutter/material.dart';
import 'package:se380_project/PageOne.dart';

void main() {
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

class PageTwo extends StatelessWidget {
  const PageTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Tests Page',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

// Sayfa 3
class PageThree extends StatelessWidget {
  const PageThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Statistics Page',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

// Sayfa 4
class PageFour extends StatelessWidget {
  const PageFour({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Settings Page',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
