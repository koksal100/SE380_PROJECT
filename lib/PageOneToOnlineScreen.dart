import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:se380_project/PageTwo.dart';

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
  late String languageCode;

  void initState() {
    if (widget.language == "German") {
      languageCode = "de";
    } else if (widget.language == "French") {
      languageCode = "fr";
    } else if (widget.language == "English") {
      languageCode = "en";
    }

    joinOnlineRoom().then((onValue) {
      setState(() {
        isLoading = false;
      });
    });
    super.initState();
  }

  Future<Map<String, dynamic>> generateWordMapForFirebase(
      String languageCode) async {
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
      final List<String> randomKeys = keys.take(30).toList();
      late Map<String, dynamic> result;

      if (languageCode == "en") {
        result = {
          for (var key in randomKeys)
            key: {
              "what_word_is_displayed": key,
              "meaning": jsonMapOfMeanings[key]
            },
        };
      } else {
        result = {
          for (var key in randomKeys)
            key: {
              "what_word_is_displayed":
                  jsonMapOfTranslations[key][languageCode].toString(),
              "meaning": jsonMapOfMeanings[key]
            },
        };
      }

      print(languageCode);
      print(result);

      return result;
    } catch (e) {
      print(e);
      return {};
    }
  }

  String maskWord(String word) {
    if (word.isEmpty) return ''; // Eğer kelime boşsa, boş döndür

    String maskedWord = '';
    Random random = Random();

    for (int i = 0; i < word.length; i++) {
      if (i % 3 == 0) {
        // Her 3 indekste bir harf göster (şansa bağlı)
        maskedWord += word[i];
      } else {
        maskedWord += ' _ '; // Diğer harfleri gizle
      }
    }

    return maskedWord;
  }

  Future<void> joinOnlineRoom() async {
    try {
      //ODA BUL
      String roomId = "";
      final roomRef = FirebaseFirestore.instance
          .collection('Languages')
          .doc(widget.language)
          .collection('WaitingRooms');
      try {
        final yarismaOdalari = await roomRef.get();
        for (var doc in yarismaOdalari.docs) {
          print("Document ID: ${doc.id}");
          print("Document Data: ${doc.data()}");
          roomId = doc.id;
        }
      } catch (e) {
        print("Error getting documents: $e");
      }
      //ODAYA KELİMELERİNİ EKLE
      generateWordMapForFirebase(languageCode).then((onValue) async {
        final currentRoom = FirebaseFirestore.instance
            .collection('Languages')
            .doc(widget.language)
            .collection('WaitingRooms')
            .doc(roomId);

        await currentRoom.update({
          "Words_map": {
            for (var key in onValue.keys)
              key: {
                "what_word_is_displayed": onValue[key]
                    ["what_word_is_displayed"],
                "meaning": onValue[key]["meaning"],
                "question_form":
                    maskWord(onValue[key]["what_word_is_displayed"])
              }
          },
        });
        //ODAYA KULLANICI BİLGİLERİNİ EKLE
        currentRoom.get().then((onValue) {
          return onValue.get("Users_map");
        }).then((onValue) {
          Map<String, dynamic> updatedDict = {
            ...onValue,
            ...{
              widget.nickname: {"user_id": 1, "score": 1}
            }
          };
          currentRoom.update({"Users_map": updatedDict});
        });
      });
    } catch (e) {
      setState(() {
        roomData = 'Hata: $e';
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: isLoading ? CircularProgressIndicator() : Text(roomData),
      ),
    );
  }
}
