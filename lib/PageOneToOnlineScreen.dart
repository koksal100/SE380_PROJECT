import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:se380_project/PageTwo.dart';
import 'package:se380_project/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'PageOne.dart';

class PageOneToOnlineScreen extends StatefulWidget {
  final String language;
  final String nickname;

  const PageOneToOnlineScreen(
      {super.key, required this.language, required this.nickname});

  @override
  State<PageOneToOnlineScreen> createState() => _PageOneToOnlineScreenState();
}

class _PageOneToOnlineScreenState extends State<PageOneToOnlineScreen> {
  @override
  bool isLoading = true;
  String roomData = "";
  String roomId = "";
  int myScore = 0;
  int opponentScore = 0;
  late var opponentId;
  late String languageCode;
  late List<dynamic> wordsMap;
  int currentQuestionIndex = 0;
  String modOfJoiningRoom = "";
  bool showAnswer = false;
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int countdown = 30;
  late Timer _timer;
  bool isWordWinningScreen = false;
  String lastWinner = "";
  String opponentNickname = "";
  bool isWordLearningScreen = false;
  bool isEmojiSended = false;
  bool isEmojiRecieved = false;
  var oldEmoji = "";
  int sameEmojiCounter = 0;
  String? selectedEmoji;
  String? opponentEmoji;
  final Map<String, String> emojis = {
    "Kudurtucu": "😜",
    "Tebrik Edici": "🎉",
    "Mutlu": "😊",
    "Üzgün": "😢",
    "Şaşkın": "😲",
    "Kızgın": "😡",
    "Düşünen": "🤔",
    "Ağlıyor": "😭",
    "Kas": "💪"
  };
  bool beforeWordLearningScreen = false;

  void initState() {
    if (widget.language == "German") {
      languageCode = "de";
    } else if (widget.language == "French") {
      languageCode = "fr";
    } else if (widget.language == "English") {
      languageCode = "en";
    }

    joinOnlineRoom().then((onValue) {
      return waitFor2Participant();
    }).then((onValue) {
      _startCountdown();
      listenRoomInformations();
    });

    super.initState();
  }

  void dispose() {
    _timer.cancel();
    _controller.dispose();
    recordScoreToTheFirebase();
    if (modOfJoiningRoom == "build" && isLoading == true) {
      final roomRef = FirebaseFirestore.instance
          .collection('Languages')
          .doc(widget.language);
      roomRef.get().then((onValue) {
        List<dynamic> waitingRoomIds = onValue.data()?["WaitingRooms"];
        waitingRoomIds.remove(roomId);
        roomRef.update({"WaitingRooms": waitingRoomIds});
      });
    }

    super.dispose();
  }
  
  void recordScoreToTheFirebase(){
    FirebaseFirestore.instance
        .collection("users")
        .doc(MyHomePageState.userId)
        .update({
      "score": FieldValue.increment(myScore),
    });
  }
  
  static void increaseCoin() {
    SharedPreferences.getInstance().then((prefs) {
      PageOneState.VocabQuizGameCoin++;
      prefs.setInt("coin", PageOneState.VocabQuizGameCoin);
    });
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        setState(() {
          beforeWordLearningScreen = true;
        });
        if (modOfJoiningRoom == "join") {
          increaseQuestionIndex();
        }
        setState(() {
          _controller.clear();
          saveWordToTheSharedPrefs();
          isWordLearningScreen = true;
          countdown = 33;
        });
        Future.delayed(Duration(seconds: 3)).then((onValue) {
          setState(() {
            isWordLearningScreen = false;
          });
        });
      }
    });
  }

  String generateUniqueId() {
    var uuid = Uuid();
    return uuid.v4();
  }

  Future<Map<String, dynamic>> generateWordMapForFirebase(String languageCode) async {
    String filePathforTranslations = r"assets/translated_words.json";
    String filePathforMeanings = r"assets/meanings.json";

    try {
      String fileContentOfTranslations =
          await rootBundle.loadString(filePathforTranslations);
      final Map<String, dynamic> jsonMapOfTranslations =
          json.decode(fileContentOfTranslations);

      String fileContentOfMeanings =
          await rootBundle.loadString(filePathforMeanings);
      final Map<String, dynamic> jsonMapOfMeanings =
          json.decode(fileContentOfMeanings);

      final List<String> keys = jsonMapOfTranslations.keys.toList()..shuffle();
      final List<String> randomKeys = keys.take(11).toList();
      late Map<String, dynamic> result;

      if (languageCode == "en") {
        result = {
          for (var key in randomKeys)
            key: {
              "what_word_is_displayed": key,
              "meaning": jsonMapOfMeanings[key],
              "kindOfWord": jsonMapOfTranslations[key]["kind"]
            },
        };
      } else {
        result = {
          for (var key in randomKeys)
            key: {
              "what_word_is_displayed":
                  jsonMapOfTranslations[key][languageCode].toString(),
              "meaning": jsonMapOfMeanings[key],
              "kindOfWord": jsonMapOfTranslations[key]["kind"]
            },
        };
      }
      return result;
    } catch (e) {
      print(e);
      return {};
    }
  }

  String maskWord(String word) {
    if (word.isEmpty) return '';

    String maskedWord = '';
    Random random = Random();

    for (int i = 0; i < word.length; i++) {
      if (i % 3 == 0) {
        maskedWord += word[i];
      } else {
        maskedWord += ' _ ';
      }
    }

    return maskedWord;
  }

  Future<void> joinOnlineRoom() async {
    //ODA BUL
    //AYARLADIĞIM STRUCTURA GÖRE İSTENİLEN DİLİN REFERANSINI ALDIM
    print(widget.language);
    final LanguageDocReferance =
        FirebaseFirestore.instance.collection('Languages').doc(widget.language);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final LanguageDocSnapshot = await transaction.get(LanguageDocReferance);
      final data = LanguageDocSnapshot.data();

      if (data == null) {
        throw Exception("Hata: LanguageDocSnapshot.data() null döndü.");
      }

      List<dynamic> waitingRoomsIds = List<dynamic>.from(data["WaitingRooms"]);
      List<dynamic> inProgressRoomsIds =
          List<dynamic>.from(data["InProgressRooms"] ?? []);

      if (waitingRoomsIds.isEmpty) {
        roomId = generateUniqueId();
        waitingRoomsIds.add(roomId);
        transaction
            .update(LanguageDocReferance, {"WaitingRooms": waitingRoomsIds});
        modOfJoiningRoom = "build";
        final roomDocReference =
            LanguageDocReferance.collection("Rooms").doc(roomId);
        transaction.set(roomDocReference, <String, dynamic>{});
      } else {
        modOfJoiningRoom = "join";
        roomId = waitingRoomsIds.removeAt(0);

        inProgressRoomsIds.add(roomId);

        transaction.update(LanguageDocReferance, {
          "WaitingRooms": waitingRoomsIds,
          "InProgressRooms": inProgressRoomsIds,
        });
      }
    });

    //WORD MAPI OLUŞTUR
    //KENDİ OLUŞTURDUĞUN YA DA IDSİNİ BULDUĞUN ODAYA GEL VE REFERANSINI AL
    await generateWordMapForFirebase(languageCode).then((onValue) async {
      final currentRoomReferance = FirebaseFirestore.instance
          .collection('Languages')
          .doc(widget.language)
          .collection('Rooms')
          .doc(roomId);

      print(currentRoomReferance);

      //ODAYA KELİMELERİNİ,USERMAPI VE QUESTION INDEXI EKLE EĞER KURUCUYSAN
      if (modOfJoiningRoom == "build") {
        await currentRoomReferance.update({
          "Words_map": [
            for (var key in onValue.keys)
              {
                "what_word_is_displayed": onValue[key]
                    ["what_word_is_displayed"],
                "meaning": onValue[key]["meaning"],
                "question_form":
                    maskWord(onValue[key]["what_word_is_displayed"]),
                "kindOfWord": onValue[key]["kindOfWord"]
              }
          ],
          "currentQuestionIndex": 0,
          "Users_map": {
            MyHomePageState.userId: {
              "nickname": widget.nickname,
              "score": 0,
              "emoji": ""
            }
          },
          "AttendanceNumber": 1,
          "lastWinner": ""
        });
      }

      //ODAYA KULLANICI BİLGİLERİNİ EKLE(HER HALÜKARDA)
      //DOCUMENT REFERANSI ÜZERİNDE SNAPSHOT ALIP VAR OLAN DİCTİONARYİ MERGE EDİP DOCUMENT REFERANSINI GÜNCELLEDİM.
      if (modOfJoiningRoom == "join") {
        await currentRoomReferance.get().then((onValue) {
          return onValue.get("Users_map");
        }).then((onValue) {
          Map<String, dynamic> updatedDict = {
            ...onValue,
            ...{
              MyHomePageState.userId: {
                "nickname": widget.nickname,
                "score": 0,
                "emoji": ""
              }
            }
          };
          currentRoomReferance
              .update({"Users_map": updatedDict, "AttendanceNumber": 2});
        });
      }
    });

    await getWordsFromFirebase();
  }

  Future<void> getWordsFromFirebase() async {
    List<dynamic> words = [];

    final currentRoom = FirebaseFirestore.instance
        .collection('Languages')
        .doc(widget.language)
        .collection('Rooms')
        .doc(roomId);

    await currentRoom.get().then((onValue) {
      words = onValue.data()?["Words_map"];
    });
    setState(() {
      wordsMap = words;
    });
    ;
  }

  bool isMatchingGuessWithActualWord(String pattern, String word) {
    pattern = pattern.replaceAll(" _ ", "_");
    word = word.replaceAll(" _ ", "_");

    if (pattern.length != word.length) {
      return false;
    }

    for (int i = 0; i < pattern.length; i++) {
      if (pattern[i].toLowerCase() != '_' && pattern[i] != word[i]) {
        return false;
      }
    }

    return true;
  }

  void revealRandomLetter() {
    if (PageOneState.VocabQuizGameCoin == 0) {
      setState(() {
        warningForCoin = true;
      });
      Future.delayed(Duration(seconds: 1)).then((onValue) {
        setState(() {
          warningForCoin = false;
        });
      });
      return;
    }
    setState(() {
      --PageOneState.VocabQuizGameCoin;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt("coin", PageOneState.VocabQuizGameCoin);
    });
    String wordToDisplay =
        wordsMap[currentQuestionIndex]["what_word_is_displayed"]!;
    String questionForm = wordsMap[currentQuestionIndex]["question_form"]!;
    questionForm = questionForm.replaceAll(" _ ", "_");
    List<String> formList = [];

    for (int i = 0; i < questionForm.length; i++) {
      formList.add(questionForm[i]);
    }

    List<int> emptyIndexes = [];

    for (int i = 0; i < formList.length; i++) {
      if (formList[i] == '_') {
        emptyIndexes.add(i);
      }
    }

    if (emptyIndexes.isNotEmpty) {
      Random random = Random();
      int randomIndex = emptyIndexes[random.nextInt(emptyIndexes.length)];
      print(randomIndex);
      print(wordToDisplay[randomIndex]);
      formList[randomIndex] = wordToDisplay[randomIndex];
    }
    String a = formList.join('').replaceAll("_", " _ ");
    wordsMap[currentQuestionIndex]["question_form"] = a;
  }

  Future<void> checkGuess() async {
    if (_formKey.currentState!.validate()) {
      if (_controller.text.toLowerCase() ==
          wordsMap[currentQuestionIndex]["what_word_is_displayed"]!
              .toString()
              .toLowerCase()) {
        final currentRoomReferance = FirebaseFirestore.instance
            .collection('Languages')
            .doc(widget.language)
            .collection('Rooms')
            .doc(roomId);

        await currentRoomReferance.get().then((currentRoomDocSnapshot) async {
          Timestamp? updateTime = currentRoomDocSnapshot.data()?["updateTime"];
          Timestamp serverTimestamp = Timestamp.now();
          String currentLastWinner =
              currentRoomDocSnapshot.data()?["lastWinner"];
          Map<String, dynamic> currentDictOfUsers =
              currentRoomDocSnapshot.data()?["Users_map"];
          int currentPoint =
              currentDictOfUsers[MyHomePageState.userId]['score'];
          currentDictOfUsers[MyHomePageState.userId]["score"] =
              currentPoint + 50 + (100 / countdown).round();

          if (updateTime == null ||
              (serverTimestamp.seconds - updateTime.seconds).abs() > 3) {
            currentRoomReferance.update({
              "Users_map": currentDictOfUsers,
              "lastWinner": lastWinner == widget.nickname
                  ? widget.nickname + " "
                  : widget.nickname,
              "currentQuestionIndex":
                  (currentRoomDocSnapshot.data()?["currentQuestionIndex"] + 1),
              "updateTime": FieldValue.serverTimestamp(),
            });
          }
        });
        _controller.clear();
      } else {
        saveWordToTheSharedPrefs();
        print("yanlış cevap");
        print(wordsMap[currentQuestionIndex]["what_word_is_displayed"]!
            .toString()
            .toLowerCase());
      }
    }
  }

  void saveWordToTheSharedPrefs() {
    SharedPreferences.getInstance().then((prefs) {
      List<String>? currentMistakes = prefs.getStringList(languageCode);
      if (currentMistakes == null) {
        print("şuanlık hata yok ama eklemeye başlıyorum");
        currentMistakes = [];
      }
      if (!currentMistakes.contains(wordsMap[currentQuestionIndex]
              ["what_word_is_displayed"]!
          .toString())) {
        currentMistakes.add(wordsMap[currentQuestionIndex]
                ["what_word_is_displayed"]!
            .toString());
      }
      print("ekledim ${currentMistakes}");
      prefs.setStringList(languageCode, currentMistakes);
    });
  }

  Future<void> waitFor2Participant() async {
    StreamSubscription? roomSubscription;

    final CurrentRoomReferance = FirebaseFirestore.instance
        .collection('Languages')
        .doc(widget.language)
        .collection('Rooms')
        .doc(roomId);

    roomSubscription = CurrentRoomReferance.snapshots().listen((onData) {
      int AttendanceNumber = onData.data()?["AttendanceNumber"];
      if (AttendanceNumber == 2) {
        roomSubscription?.cancel();
        roomSubscription = null;
        if (mounted) {
          setState(() {
            countdown = 30;
            isLoading = false;
            return;
          });
        }
      }
    });
  }

  void listenRoomInformations() {
    int oldcurrentQuestionIndex = 0;
    final CurrentRoomReferance = FirebaseFirestore.instance
        .collection('Languages')
        .doc(widget.language)
        .collection('Rooms')
        .doc(roomId);
    CurrentRoomReferance.snapshots().listen((onData) {
      if (opponentNickname == "") {
        onData.data()?["Users_map"].forEach((key, value) {
          if (value["nickname"] != widget.nickname && mounted) {
            setState(() {
              opponentNickname = value["nickname"];
              opponentId = key;
            });
          }
        });
      }

      var newWinner = onData.data()?["lastWinner"];
      if (newWinner != lastWinner && mounted) {
        _controller.clear();
        setState(() {
          isWordWinningScreen = true;
          lastWinner = newWinner;
          countdown = 34;
          if (mounted) {
            Future.delayed(Duration(seconds: 4)).then((onvalue) {
              if (mounted) {
                setState(() {
                  isWordWinningScreen = false;
                });
              }
            });
          }
        });
      }
      if (opponentId != null) {
        opponentEmoji = onData.data()?["Users_map"][opponentId]["emoji"];
        if (opponentEmoji != oldEmoji && mounted) {
          isEmojiRecieved = true;
          Future.delayed(Duration(seconds: 2)).then((onValue) {
            setState(() {
              isEmojiRecieved = false;
              oldEmoji = opponentEmoji ?? "";
            });
          });
        }
      }

      if (mounted) {
        setState(() {
          currentQuestionIndex = onData.data()?["currentQuestionIndex"];
          if (oldcurrentQuestionIndex != currentQuestionIndex) {
            setState(() {
              beforeWordLearningScreen = false;
              oldcurrentQuestionIndex = currentQuestionIndex;
            });
          }
          myScore =
              onData.data()?["Users_map"][MyHomePageState.userId]["score"];
          if (opponentNickname != "") {
            opponentScore = onData.data()?["Users_map"][opponentId]["score"];
          }
          if (currentQuestionIndex == 10) {
            if (myScore > opponentScore) {
              increaseCoin();
            }
            return;
          }
        });
      }
    });
  }

  void showAnswerFunc() {
    setState(() {
      showAnswer = !showAnswer;
    });
  }

  void increaseQuestionIndex() async {
    final currentRoomReferance = FirebaseFirestore.instance
        .collection('Languages')
        .doc(widget.language)
        .collection('Rooms')
        .doc(roomId);
    _controller.clear();
    await currentRoomReferance.get().then((currentRoomDocSnapshot) async {
      currentRoomReferance.update({
        "currentQuestionIndex":
            (currentRoomDocSnapshot.data()?["currentQuestionIndex"] + 1)
      });
    });
  }

  void sendEmojiToOpponent(String emoji) async {
    if (emoji == selectedEmoji) {
      sameEmojiCounter++;
    } else {
      sameEmojiCounter = 0;
    }
    print(selectedEmoji);
    FirebaseFirestore.instance
        .collection('Languages')
        .doc(widget.language)
        .collection('Rooms')
        .doc(roomId)
        .update({
      "Users_map.${MyHomePageState.userId}.emoji": emoji == selectedEmoji
          ? (emoji + "   " * (sameEmojiCounter % 2))
          : emoji,
    }).then((onValue) {
      setState(() {
        isEmojiSended = true;
        print("emoji yollandı --${emoji}--");
      });
    });
    Future.delayed(Duration(seconds: 1)).then((onValue) {
      isEmojiSended = false;
    });
  }

  bool warningForCoin = false;

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(
                "Online Word Competition",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              AnimatedContainer(
                  duration: Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  child: IconButton(
                      onPressed: null,
                      icon: Icon(
                        Icons.monetization_on,
                        color: warningForCoin ? Colors.red : Colors.amber,
                      ))),
              Text(
                "${PageOneState.VocabQuizGameCoin}",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            ],
          ),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 194, 164, 244),
        ),
        body: Form(
          key: _formKey,
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Waiting for an opponent",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      CircularProgressIndicator(),
                    ],
                  )
                : isWordWinningScreen
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          color: Colors.purple.shade100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${wordsMap[currentQuestionIndex - 1]["what_word_is_displayed"]}',
                                style: TextStyle(
                                  fontSize: 45,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade500,
                                  letterSpacing: 5,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 7,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Divider(
                                color: Colors.purple.shade300,
                                thickness: 3,
                              ),
                              Text(
                                '👑\n${lastWinner} \nhit the nail\n on the head.',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                  letterSpacing: 5,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 7,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : currentQuestionIndex > 9
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "END OF THE GAME",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 40,
                                    color: Colors.purple,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                      )
                                    ]),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20),
                              Text(
                                myScore > opponentScore
                                    ? "YOU WIN${myScore}"
                                    : myScore < opponentScore
                                        ? "YOU LOSE"
                                        : " DRAW ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 52,
                                  color: myScore > opponentScore
                                      ? Colors.green
                                      : Colors.red,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: (myScore > opponentScore
                                          ? Colors.green
                                          : Colors.red),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : beforeWordLearningScreen
                            ? Center(child: CircularProgressIndicator())
                            : isWordLearningScreen
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "THE WORD WAS",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 40,
                                            color: Colors.purple,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 4,
                                              )
                                            ]),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        '${wordsMap[currentQuestionIndex - 1]["what_word_is_displayed"]}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 52,
                                          color: Colors.purple,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 4,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      DropdownButton<String>(
                                                        value: selectedEmoji,
                                                        hint: Text(
                                                          "${emojis.values.first}",
                                                          style: TextStyle(
                                                              fontSize: 30),
                                                        ),
                                                        items: emojis.entries
                                                            .map((entry) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: entry.value,
                                                            child: Text(
                                                              "${entry.value}",
                                                              style: TextStyle(
                                                                  fontSize: 30),
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            sendEmojiToOpponent(
                                                                value ?? " ");
                                                            selectedEmoji =
                                                                value;
                                                          });
                                                        },
                                                      ),
                                                      if (selectedEmoji != null)
                                                        AnimatedOpacity(
                                                          opacity: isEmojiSended
                                                              ? 1.0
                                                              : 0,
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      300),
                                                          child: Text(
                                                            selectedEmoji!,
                                                            style: TextStyle(
                                                                fontSize: 20),
                                                          ),
                                                        )
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      if (opponentEmoji != null)
                                                        AnimatedScale(
                                                          scale: isEmojiRecieved
                                                              ? 1
                                                              : 0,
                                                          duration:
                                                              const Duration(
                                                                  milliseconds:
                                                                      900),
                                                          child:
                                                              AnimatedOpacity(
                                                            opacity:
                                                                isEmojiRecieved
                                                                    ? 1
                                                                    : 0,
                                                            duration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        900),
                                                            child: Text(
                                                              opponentEmoji!,
                                                              style: TextStyle(
                                                                  fontSize: 40),
                                                            ),
                                                          ),
                                                        )
                                                      else
                                                        Text(
                                                            'Henüz bir emoji gönderilmedi'),
                                                    ],
                                                  ),
                                                ),
                                              ]),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person,
                                                        color: Colors.green,
                                                        size: 43,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        "${myScore}",
                                                        style: TextStyle(
                                                          fontSize: 24,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    widget.nickname,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  )
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  Icon(
                                                    Icons.timer,
                                                    color: Color.fromARGB(
                                                        255, 213, 200, 237),
                                                    size: 40,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    "$countdown",
                                                    style: TextStyle(
                                                      fontSize: 29,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromARGB(
                                                          255, 102, 53, 186),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "${opponentScore}",
                                                        style: TextStyle(
                                                          fontSize: 24,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Icon(
                                                        Icons.person,
                                                        color: Colors.red,
                                                        size: 40,
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    opponentNickname,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                          Text(
                                            "Question ${currentQuestionIndex + 1} of ${wordsMap.length - 1}",
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 67, 67, 67),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                            height: 29,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255, 213, 200, 237),
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black,
                                                  spreadRadius: 2,
                                                  blurRadius: 11,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  "Meaning",
                                                  style: TextStyle(
                                                    fontSize: 25,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: "Monospace",
                                                    color: const Color.fromARGB(
                                                        255, 102, 53, 186),
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                                Text(
                                                  "${wordsMap[currentQuestionIndex]["meaning"]} (${wordsMap[currentQuestionIndex]["kindOfWord"] ?? " "})" ??
                                                      " ",
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontFamily: "Monospace",
                                                      color:
                                                          const Color.fromARGB(
                                                              221, 0, 0, 0),
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 39),
                                          Container(
                                            padding: const EdgeInsets.all(11),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255, 213, 200, 237),
                                              borderRadius:
                                                  BorderRadius.circular(90),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black,
                                                  spreadRadius: 3,
                                                  blurRadius: 15,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  "Fill in the blanks",
                                                  style: TextStyle(
                                                    fontFamily: "Monospace",
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color.fromARGB(
                                                        255, 99, 22, 241),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      wordsMap[
                                                              currentQuestionIndex]
                                                          ["question_form"]!,
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: const Color
                                                            .fromARGB(
                                                            221, 0, 0, 0),
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    IconButton(
                                                        onPressed:
                                                            revealRandomLetter,
                                                        icon: Icon(
                                                            Icons.question_mark,
                                                            color:
                                                                Colors.purple,
                                                            size: 32))
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: 45,
                                          ),
                                          TextFormField(
                                            validator: (value) {
                                              print("validator çağrıldı");
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Empty guess is not valid!';
                                              } else if (!isMatchingGuessWithActualWord(
                                                  wordsMap[currentQuestionIndex]
                                                      ["question_form"]!,
                                                  value)) {
                                                return 'Your guess should be matching with given clues';
                                              }
                                              return null;
                                            },
                                            controller: _controller,
                                            decoration: InputDecoration(
                                              labelText: 'Enter your guess',
                                              labelStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold),
                                              prefixIcon: Icon(
                                                  Icons.text_fields,
                                                  color: Colors.grey),
                                              suffixIcon: ElevatedButton(
                                                  style: ButtonStyle(
                                                      backgroundColor:
                                                          WidgetStatePropertyAll(
                                                              Color.fromARGB(
                                                                  255,
                                                                  213,
                                                                  200,
                                                                  237))),
                                                  onPressed: checkGuess,
                                                  child: Text(
                                                    "Submit",
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  )),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                                borderSide: BorderSide(
                                                    color: Colors.purple,
                                                    width: 4),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(39),
                                                borderSide: BorderSide(
                                                    color: Color.fromARGB(
                                                        255, 213, 200, 237),
                                                    width: 4),
                                              ),
                                            ),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                fontFamily: "Monospace",
                                                letterSpacing: 1),
                                          ),
                                          //ElevatedButton(onPressed: showAnswerFunc, child: Text(showAnswer?"${wordsMap[currentQuestionIndex]["what_word_is_displayed"]}":"click here to show word"))
                                        ],
                                      ),
                                    ),
                                  ),
          ),
        ));
  }
}
