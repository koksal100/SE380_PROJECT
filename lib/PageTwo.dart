import 'dart:ffi';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

class PageTwo extends StatefulWidget {
  const PageTwo({super.key});

  _PageTwoState createState() => _PageTwoState();
}

class _PageTwoState extends State<PageTwo> {
  final Random random = Random();
  late List<String> currentChoices;
  late Future<Map<String, String>> futurefailedWordsByUser;
  late Map<String, String> failedWordsByUser;
  late Map<String, dynamic> choicesMap;

  bool isfailedWordsByUserLoaded = false;
  int wordIndex = 0;

  @override
  void initState() {
    choicesMapFuture("assets/choices.json").then((onValue) {
      setState(() {
        choicesMap = onValue;
      });
      return readRandomWordsFromFile("assets/translated_words.json");
    }).then((onValue) {
      if (onValue.isEmpty) {
        print("veri bulunamadı");
      } else {
        setState(() {
          failedWordsByUser = onValue;
        });
      }
      return fillCurrentChoices(failedWordsByUser.keys.toList()[0]);
    }).then((onValue) {
      setState(() {
        isfailedWordsByUserLoaded = true;
      });
    });

    super.initState();
  }

  Future<Map<String, String>> readRandomWordsFromFile(String filePath) async {
    try {
      String fileContent = await rootBundle.loadString(filePath);
      final Map<String, dynamic> jsonMap = json.decode(fileContent);

      final List<String> keys = jsonMap.keys.toList()..shuffle();

      final List<String> randomKeys = keys.take(30).toList();

      final Map<String, String> result = {
        for (var key in randomKeys) key: jsonMap[key]['tr'].toString(),
      };
      return result;
    } catch (e) {
      print(e);
      return {};
    }
  }

  Future<Map<String, dynamic>> choicesMapFuture(String filePath) async {
    try {
      String fileContent = await rootBundle.loadString(filePath);
      final Map<String, dynamic> jsonMap = json.decode(fileContent);
      return jsonMap;
    } catch (e) {
      print(e);
      return {};
    }
  }

  Future fillCurrentChoices(String word) async {
    int wrongChoicesIndex = 0;
    List<String> currentChoicesLocal = [
      "Wrong Choice",
      "Wrong Choice",
      "Wrong Choice",
      "Wrong Choice"
    ];
    List<dynamic> wrongChoices = choicesMap[word];
    currentChoicesLocal[random.nextInt(4)] = failedWordsByUser[word]!;
    for (int i = 0; i < currentChoicesLocal.length; i++) {
      if (currentChoicesLocal[i] == "Wrong Choice") {
        currentChoicesLocal[i] = wrongChoices[wrongChoicesIndex++];
      }
    }
    setState(() {
      currentChoices = currentChoicesLocal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: isfailedWordsByUserLoaded
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFB39DDB),
                            Color.fromARGB(255, 151, 122, 205),
                            Color.fromARGB(255, 227, 159, 237),
                          ],
                          begin: Alignment.topLeft, // Geçişin başlangıç noktası
                          end: Alignment.bottomRight, // Geçişin bitiş noktası
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Color(0xFFB39DDB),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0), // İç boşluk
                        child: Text(
                          "${failedWordsByUser.keys.toList()[wordIndex]}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                            color: Color.fromARGB(
                                255, 255, 255, 255), // Yazı rengi
                            shadows: [
                              Shadow(
                                offset:
                                    Offset(1.0, 1.0), // Yazı gölgesinin kayması
                                blurRadius: 2.0, // Yazı gölgesinin bulanıklığı
                                color: Colors.black
                                    .withOpacity(0.3), // Yazı gölgesinin rengi
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  ...currentChoices.map((word) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        width: 250,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              wordIndex++;
                              fillCurrentChoices(
                                  failedWordsByUser.keys.toList()[wordIndex]);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFB39DDB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            word,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
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
