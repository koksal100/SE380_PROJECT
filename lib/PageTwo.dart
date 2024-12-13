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
  int trueCounter = 0;
  int falseCounter = 0;

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

  void checkValidity(String answer) {
    if (answer ==
        failedWordsByUser[failedWordsByUser.keys.toList()[wordIndex]]!) {
      trueCounter++;
    } else {
      falseCounter++;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(children: [
        Positioned(
          left: 10,
          top: 10,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 198, 237, 200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 40,
                ),
                SizedBox(width: 8),
                Text(
                  "$trueCounter",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: const Color.fromARGB(255, 37, 123, 42),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 228, 230),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 40,
                ),
                SizedBox(width: 8),
                Text(
                  "$falseCounter",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
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
                              Color.fromARGB(255, 149, 107, 227),
                              Color.fromARGB(255, 227, 159, 237),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.topRight,
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 5, vertical: 15),
                          child: Text(
                            "${failedWordsByUser.keys.toList()[wordIndex]}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                              color: Color.fromARGB(255, 255, 255, 255),
                              shadows: [
                                Shadow(
                                  offset: Offset(1.0, 1.0),
                                  blurRadius: 2.0,
                                  color: Colors.black.withOpacity(0.3),
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
                        padding: const EdgeInsets.all(13),
                        child: Container(
                          width: 300,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                checkValidity(word);
                                wordIndex++;
                                fillCurrentChoices(
                                    failedWordsByUser.keys.toList()[wordIndex]);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 154, 117, 224),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
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
      ]),
    );
  }
}
