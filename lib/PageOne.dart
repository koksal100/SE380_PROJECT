import 'package:flutter/material.dart';

class PageOne extends StatefulWidget {
  const PageOne({super.key});

  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  int currentIndex = 0;
  final List<String> languages = ['Almanca', 'İngilizce', 'Fransızca'];
  final List<String> imagePaths = [
    'assets/almanya.jpg',
    'assets/uk.jpg',
    'assets/fransa.png',
  ];

  bool isRaceStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isRaceStarted) ...[
            SizedBox(
              height: 120,
              child: Center(
                child: PageView.builder(
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index % imagePaths.length;
                    });
                  },
                  controller: PageController(viewportFraction: 0.55),
                  itemBuilder: (context, index) {
                    final actualIndex = index % imagePaths.length;
                    final isSelected = actualIndex == currentIndex;
                    return AnimatedScale(
                      scale: isSelected ? 1.0 : 0.6,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 1200),
                        opacity: isSelected ? 1.0 : 0.5,
                        child: Image.asset(
                          imagePaths[actualIndex],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Seçilen dil: ${languages[currentIndex]}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE0BBE4), // Açık mor
                    Color.fromARGB(255, 144, 103, 185),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(33.0),
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isRaceStarted = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.deepPurple[100],
                  elevation: 5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                child: const Text(
                  "Yarışa Başla",
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          if (isRaceStarted) ...[
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isRaceStarted = false;
                  });
                },
                child: const Text('Yarışı Bitir'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
