import 'dart:ffi';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


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
  late Map<String, dynamic> Translations;
  String selectedLanguage = "";
  final Map<String, String> languageKeys = {
    "German": "de",
    "English": "en",
    "French": "fr"
  };

  bool isQuizStarted = false;

  @override
  void initState() {
    super.initState();
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


  }


  String turnToBaseLanguage(String word,String baseLanguageCode){
    return Translations[word][baseLanguageCode];
  }

  Future<Map<String, String>> readRandomWordsFromFile(String filePath) async {
    try {
      String fileContent = await rootBundle.loadString(filePath);
      final Map<String, dynamic> jsonMap = json.decode(fileContent);
      Translations=jsonMap;
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

  Future<void> startQuizForLanguage(String language) async {
    selectedLanguage = language;
    final String key = languageKeys[language]!;
    failedWordsByUser = await readFailedWordsFromPreferences(key);

    if(failedWordsByUser.isNotEmpty) {
      await fillCurrentChoices(failedWordsByUser.keys.toList()[wordIndex]);
      setState(() {
        isfailedWordsByUserLoaded = true;
        isQuizStarted = true;
      });
    } else {
      showNoWordsDialog();
    }

  }

  Future<Map<String,String>> readFailedWordsFromPreferences(String key) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> words = prefs.getStringList(key) ?? [];
    return {for (var word in words) word: word};
  }

  void checkValidity(String answer) {
    if (answer ==
        failedWordsByUser[failedWordsByUser.keys.toList()[wordIndex]]!) {
      trueCounter++;
    } else {
      falseCounter++;
    }
    setState(() {
      wordIndex++;
      if(wordIndex< failedWordsByUser.length) {
        fillCurrentChoices(failedWordsByUser.keys.toList()[wordIndex]);
      }
    });
  }

  void showNoWordsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("No Words to Repractice"),
          content: Text("You don't have any wrongly answered words in this language."),
          actions: [
            TextButton( child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> getWordsFromPreferences(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }
  Future<void> saveWordsToPreferences(String key, List<String> words) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, words);
  }
  Future<void> moveWordToCorrectlyLearned(String word) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> wrongWords = await getWordsFromPreferences('wrong_words');
    List<String> correctWords = await getWordsFromPreferences('correct_words');
    if (wrongWords.contains(word)) {
      wrongWords.remove(word);
      correctWords.add(word);
      await saveWordsToPreferences('wrong_words', wrongWords);
      await saveWordsToPreferences('correct_words', correctWords);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Repractice Page")),
      body: isQuizStarted
          ? buildQuizUI()
          : buildLanguageSelectionUI(),
    );
  }

  Widget buildLanguageSelectionUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Select a Language to Repractice",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ...languageKeys.keys.map((language) {
            return ElevatedButton(
              onPressed: () => startQuizForLanguage(language),
              child: Text(language),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget buildQuizUI() {
    if (wordIndex >= failedWordsByUser.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Repractice Completed!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text("Correct Answers: $trueCounter"),
            Text("Incorrect Answers: $falseCounter"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isQuizStarted = false;
                  wordIndex = 0;
                  trueCounter = 0;
                  falseCounter = 0;
                });
              },
              child: Text("Back to Menu"),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
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
          child: Column(
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
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
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
                        checkValidity(word);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 154, 117, 224),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        turnToBaseLanguage(word,"tr"),
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
          ),
        ),
      ],
    );
  }
}