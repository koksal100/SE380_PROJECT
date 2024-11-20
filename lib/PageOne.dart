import 'package:flutter/material.dart';

class PageOne extends StatefulWidget {
  const PageOne({super.key});

  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  int currentIndex = 0; // Seçilen bayrağın indeksi
  final List<String> languages = ['Almanca', 'İngilizce', 'Fransızca'];
  final List<String> imagePaths = [
    'assets/almanya.jpg',
    'assets/uk.jpg',
    'assets/fransa.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 120,
            child: Center(
              child: PageView.builder(
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index % imagePaths.length;
                  });
                },
                //current index değeri bir mod fonksiyonuyla ilgili dile atanıyor
                controller: PageController(viewportFraction: 0.55),
                //ortadaki elemanın sayfanın yüzde kaçını kapsadığı parametre ile belirleniyor
                itemBuilder: (context, index) {
                  final actualIndex = index % imagePaths.length;
                  final isSelected = actualIndex == currentIndex;
                  return AnimatedScale(
                    scale: isSelected ? 1.0 : 0.6,
                    // Seçili değilse öğeyi küçült

                    duration: const Duration(milliseconds: 300),
                    //animasyonun gerçekleştiği süre

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
        ],
      ),
    );
  }
}
