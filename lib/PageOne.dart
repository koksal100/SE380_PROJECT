import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:se380_project/PageOneToOnlineScreen.dart';
import 'package:se380_project/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PageOne extends StatefulWidget {
  const PageOne({super.key});

  @override
  State<PageOne> createState() => PageOneState();
}

class PageOneState extends State<PageOne> {
  int currentIndex = 0;
  String reccomendedWordEnglish = "";
  String reccomendedWord = "";
  String meaningOfWord = "";
  late final Map<String, dynamic> jsonMapOfTranslations;
  late final Map<String, dynamic> jsonMapOfMeanings;
  final List<String> languages = ['German', 'English', 'French'];
  final List<String> imagePaths = [
    'assets/almanya.jpg',
    'assets/uk.jpg',
    'assets/fransa.png',
  ];

  bool isRaceStarted = false;
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  static int VocabQuizGameCoin = 10;
  final TextEditingController _usernameController = TextEditingController();
  bool controllingUsernameSuitable =false;

  void _submitUsername() {
    setState(() {
      controllingUsernameSuitable=true;
    });
    if (_usernameController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('users').get().then((snapshot) {
        List<String> documentIds = snapshot.docs.map((doc) => doc.id).toList();

        if(_usernameController.text.toString().trim().length<4){
          setState(() {
            controllingUsernameSuitable=false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Username should have at least 4 characters'),
            ),
          );
        }
        else if (documentIds.contains(_usernameController.text.toString().trim())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'This username has already taken ${_usernameController.text}'),
            ),
          );
          setState(() {
            controllingUsernameSuitable=false;
          });
        } else {
          FirebaseFirestore.instance
              .collection('users')
              .doc(_usernameController.text.toString().trim())
              .set({"created_at": DateTime.now().toUtc(),"score":0});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'This username -${_usernameController.text.toString().trim()}- has been succesfully recorded'),
            ),
          );
          setState(() {
            MyHomePageState.determineUserId=false;
            MyHomePageState.userId=_usernameController.text.toString().trim();
          });
          SharedPreferences.getInstance().then((onValue){
            onValue.setString("UserId", _usernameController.text.toString().trim());
          });
        }
      });
    } else {
      setState(() {
        controllingUsernameSuitable=false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a username.'),
        ),
      );
    }
  }
  @override
  void initState() {
    initCoin();
    initializeRandomWordCircle();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void initCoin() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        VocabQuizGameCoin = prefs.getInt("coin") ?? 0 + 10;
      });
    });
  }

  void initializeRandomWordCircle() async {
    String filePathforTranslations = r"assets/translated_words.json";
    String filePathforMeanings = r"assets/meanings.json";

    String fileContentOfTranslations =
        await rootBundle.loadString(filePathforTranslations);
    jsonMapOfTranslations = json.decode(fileContentOfTranslations);

    String fileContentOfMeanings =
        await rootBundle.loadString(filePathforMeanings);
    jsonMapOfMeanings = json.decode(fileContentOfMeanings);
    setState(() {
      reccomendedWord = jsonMapOfTranslations.keys
          .toList()[Random().nextInt(jsonMapOfTranslations.length)];
      reccomendedWordEnglish = reccomendedWord;
      reccomendedWord = jsonMapOfTranslations[reccomendedWord]["de"];
    });
  }

  void updateCurrentReccomendedWord() {
    setState(() {
      if (languages[currentIndex] == "German") {
        reccomendedWord = jsonMapOfTranslations[reccomendedWordEnglish]["de"];
      } else if (languages[currentIndex] == "French") {
        reccomendedWord = jsonMapOfTranslations[reccomendedWordEnglish]["fr"];
      } else if (languages[currentIndex] == "English") {
        reccomendedWord = reccomendedWordEnglish;
      }
    });
  }

  void RefreshTheRandomWord() {
    String randomKey = jsonMapOfTranslations.keys
        .toList()[Random().nextInt(jsonMapOfTranslations.length)];
    reccomendedWordEnglish = randomKey;
    updateCurrentReccomendedWord();
  }

  void SaveTheWord() {
    String languageCode = "";
    if (languages[currentIndex] == "German") {
      languageCode = "de";
    } else if (languages[currentIndex] == "French") {
      languageCode = "fr";
    } else if (languages[currentIndex] == "English") {
      languageCode = "en";
    }

    SharedPreferences.getInstance().then((prefs) {
      List<String> currentWords = prefs.getStringList(languageCode) ?? [];
      if (!currentWords.contains(reccomendedWordEnglish)) {
        currentWords.add(reccomendedWordEnglish);
        print("$reccomendedWordEnglish kaydedildi.");
      }
      prefs.setStringList(languageCode, currentWords);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 174, 133, 231),
        title: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                "Vocab Quiz Game",
              ),
              Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                      onPressed: null,
                      icon: Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                      ))),
              Text(
                "${VocabQuizGameCoin}",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
      ),
      body: MyHomePageState.determineUserId
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (controllingUsernameSuitable)
                      CircularProgressIndicator(),
                    SizedBox(height: 20,),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            'Determine Your Username',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade800,
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your username',
                              hintStyle: TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(
                                    color: Colors.deepPurple, width: 2),
                              ),
                            ),
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _submitUsername,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 5,
                            ),
                            child: Text(
                              'Determine',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isRaceStarted) ...[
                      SizedBox(
                        height: 40,
                      ),
                      SizedBox(
                        height: 120,
                        child: Center(
                          child: PageView.builder(
                            onPageChanged: (index) {
                              setState(() {
                                currentIndex = index % imagePaths.length;
                                updateCurrentReccomendedWord();
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
                        'Choosen language: ${languages[currentIndex]}',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 250,
                        child: TextFormField(
                            textAlign: TextAlign.start,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'This area can not be empty!';
                              } else if (value.length < 4) {
                                return 'Nickname should contain at least 5 characters';
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
                                      color:
                                          Color.fromARGB(255, 174, 133, 231)),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(24.0))),
                              hintText: 'Enter the nickname...',
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
                              ).then((onValue) {
                                setState(() {
                                  initCoin();
                                });
                              });
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
                            "Start game",
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 250,
                            width: 300,
                            child: DecoratedBox(
                                decoration: BoxDecoration(
                                    boxShadow: [
                                  BoxShadow(
                                    color: Colors.black,
                                    spreadRadius: 2,
                                    blurRadius: 11,
                                  ),
                                ],
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFE0BBE4),
                                        Color.fromARGB(255, 136, 89, 182),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    color: Colors.purple,
                                    shape: BoxShape.circle)),
                          ),
                          Positioned(
                              top: 5,
                              child: IconButton(
                                  onPressed: RefreshTheRandomWord,
                                  icon: Icon(
                                    size: 29,
                                    color: Colors.black,
                                    Icons.lightbulb,
                                  ))),
                          Positioned(
                              bottom: 5,
                              child: IconButton(
                                  onPressed: RefreshTheRandomWord,
                                  icon: Icon(
                                    size: 29,
                                    color: Colors.black,
                                    Icons.refresh,
                                  ))),
                          Positioned(
                              left: 35,
                              child: IconButton(
                                  onPressed: SaveTheWord,
                                  icon: Icon(
                                    size: 29,
                                    color: Colors.black,
                                    Icons.save,
                                  ))),
                          Positioned(
                              right: 35,
                              child: IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(
                                              'Meaning of the ${reccomendedWord}'),
                                          content: Text(jsonMapOfMeanings[
                                                  reccomendedWordEnglish] ??
                                              ""),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Close'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    size: 29,
                                    color: Colors.black,
                                    Icons.info,
                                  ))),
                          Positioned(
                              child: Text(
                            reccomendedWord.toString().replaceAll(" ", "\n"),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    reccomendedWord.length > 12 ? 18 : 25),
                          ))
                        ],
                      )
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
            ),
    );
  }
}
