import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

class PageTwo extends StatefulWidget {
  const PageTwo({super.key});

  _PageTwoState createState() => _PageTwoState();
}

class _PageTwoState extends State<PageTwo> {
  List<String> currentChoices = ["Choice1", "Choice2", "Choice3", "Choice4"];
  late Future<List<String>> futurefailedWordsByUser;
  late List<String> failedWordsByUser;
  bool isfailedWordsByUserLoaded = false;
  int wordIndex = 0;

  @override
  void initState() {
    futurefailedWordsByUser =
        readRandomWordsFromFile("assets/translated_words.json");
    futurefailedWordsByUser.then((onValue) {
      if (onValue.isEmpty) {
        print("veri bulunamadı");
      } else {
        setState(() {
          failedWordsByUser = onValue;
          isfailedWordsByUserLoaded = true;
        });
      }
    });
    super.initState();
  }

  Future<List<String>> readRandomWordsFromFile(String FilePath) async {
    await Future.delayed(Duration(seconds: 2), () {});

    try {
      String fileContent = await rootBundle.loadString(FilePath);
      final Map<String, dynamic> jsonMap = json.decode(fileContent);
      final List<String> keys = jsonMap.keys.toList();
      final Random random = Random();
      final List<String> randomKeys = (keys..shuffle(random)).take(30).toList();
      return randomKeys;
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: isfailedWordsByUserLoaded
            ? Column(
                children: [
                  Text(
                      "What is the meaning of ${failedWordsByUser[wordIndex]}"),
                  SizedBox(height: 50),
                  ...currentChoices.map((word) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              wordIndex++;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(
                                0xFFB39DDB), // Açık mor tonunu belirliyoruz
                            foregroundColor:
                                Colors.white, // Buton metninin rengi
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(30.0), // Köşe yuvarlama
                            ),
                            elevation: 5, // Gölgelendirme ekliyoruz
                          ),
                          child: Text(
                            word,
                            style: TextStyle(
                              fontSize: 18, // Yazı boyutu
                              fontWeight:
                                  FontWeight.bold, // Yazı tipi kalınlığı
                              letterSpacing: 1.0, // Harfler arasına boşluk
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}
