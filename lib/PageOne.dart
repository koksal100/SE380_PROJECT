import 'package:flutter/material.dart';
import 'package:se380_project/PageOneToOnlineScreen.dart';

class PageOne extends StatefulWidget {
  const PageOne({super.key});

  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  int currentIndex = 0;
  final List<String> languages = ['German', 'English', 'French'];
  final List<String> imagePaths = [
    'assets/almanya.jpg',
    'assets/uk.jpg',
    'assets/fransa.png',
  ];

  bool isRaceStarted = false;
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
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
              Container(
                width: 250,
                child: TextFormField(
                    textAlign: TextAlign.start,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bu alan boş bırakılamaz!';
                      } else if (value.length < 4) {
                        return 'Nickname en az 5 karakterden oluşmalıdır';
                      }
                      return null;
                    },
                    controller: _controller,
                    decoration: InputDecoration(
                      errorMaxLines: 2,
                      errorStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 9,
                              color: Color.fromARGB(255, 174, 133, 231)),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(24.0))),
                      hintText: 'Nickname giriniz...',
                    )),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE0BBE4),
                      Color.fromARGB(255, 144, 103, 185),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(33.0),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PageOneToOnlineScreen(
                                nickname: _controller.text,
                                language: languages[currentIndex])),
                      );
                    }
                    ;
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
      ),
    );
  }
}
