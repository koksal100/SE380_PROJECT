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
  String roomId = "";
  late String languageCode;
  late Map<String, dynamic> wordsMap;
  int currentQuestionIndex = 0;
  String modOfJoiningRoom = "";

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
    print("printÇalışıyor");
    int InProgressRoomsLength = 0;
    try {
      //ODA BUL
      //AYARLADIĞIM STRUCTURA GÖRE İSTENİLEN DİLİN BEKLEME ODASININ REFERANSINI ALDIM
      final waitingRoomsReferance = FirebaseFirestore.instance
          .collection('Languages')
          .doc(widget.language)
          .collection('WaitingRooms');

      try {
        final yarismaOdalari = await waitingRoomsReferance.get();
        //HALİHAZIRDA ODA YOKSA KENDİN OLUŞTUR VE ID'SİNİ ASSIGN ET
        if (yarismaOdalari.docs.length == 0) {
          modOfJoiningRoom = "build";
          setState(() {
            roomId = "Room_1";
          });
          await waitingRoomsReferance.doc("Room_1").set({});
        } else {
          //ZATEN ODA VARSA SADECE ID'SİNİ AL
          modOfJoiningRoom = "join";
          for (var doc in yarismaOdalari.docs) {
            roomId = doc.id;
          }
        }
      } catch (e) {
        print("Error getting documents: $e");
      }

      //WORD MAPI OLUŞTUR
      //KENDİ OLUŞTURDUĞUN YA DA IDSİNİ BULDUĞUN ODAYA GEL VE REFERANSINI AL
      await generateWordMapForFirebase(languageCode).then((onValue) async {
        final currentRoomReferance = FirebaseFirestore.instance
            .collection('Languages')
            .doc(widget.language)
            .collection('WaitingRooms')
            .doc(roomId);

        //ODAYA KELİMELERİNİ,USERMAPI VE QUESTION INDEXI EKLE EĞER KURUCUYSAN
        if (modOfJoiningRoom == "build") {
          await currentRoomReferance.update({
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
            "currentQuestionIndex": 0,
            "Users_map": {}
          });
        }

        //ODAYA KULLANICI BİLGİLERİNİ EKLE(HER HALÜKARDA)
        //DOCUMENT REFERANSI ÜZERİNDE SNAPSHOT ALIP VAR OLAN DİCTİONARYİ MERGE EDİP DOCUMENT REFERANSINI GÜNCELLEDİM.
        await currentRoomReferance.get().then((onValue) {
          return onValue.get("Users_map");
        }).then((onValue) {
          Map<String, dynamic> updatedDict = {
            ...onValue,
            ...{
              widget.nickname: {"user_id": 1, "score": 1}
            }
          };
          currentRoomReferance.update({"Users_map": updatedDict});
        }).then((onValue) async {
          if (modOfJoiningRoom == "join") {
            await FirebaseFirestore.instance
                .collection('Languages')
                .doc(widget.language)
                .collection('InProgressRooms')
                .get()
                .then((onValue) {
              InProgressRoomsLength = onValue.docs.length;
            });

            //DOCUMENT REFERANSI ÜZERİNDE SNAPSHOT ALIP -DATASINA ULAŞMAK İÇİN- BU DDOKUMENTI VAR OLAN BAŞKA BİR COLLECTIONA EKLEDİM YENİ BİR ID İLE
            waitingRoomsReferance.doc(roomId).get().then((onValue) async {
              await FirebaseFirestore.instance
                  .collection('Languages')
                  .doc(widget.language)
                  .collection('InProgressRooms')
                  .doc("Room_${InProgressRoomsLength + 1}")
                  .set(onValue.data()!);
              //HALİHAZIRDA BULUNDUĞUM COLLECTION REFERANSI ÜZERİNDEN AZ ÖNCE TAŞIDIĞIM DOCUMENTİ SİLDİM
              await waitingRoomsReferance.doc(roomId).delete().then((onValue) {
                setState(() {
                  roomId = "Room_${InProgressRoomsLength + 1}";
                });
              });
            });
          }
        });
      });
    } catch (e) {
      setState(() {
        roomData = 'Hata: $e';
      });
    }

    await getWordsFromFirebase();
  }

  Future<void> getWordsFromFirebase() async {
    Map<String, dynamic> words = {};
    final currentRoom = FirebaseFirestore.instance
        .collection('Languages')
        .doc(widget.language)
        .collection('WaitingRooms')
        .doc(roomId);

    await currentRoom.get().then((onValue) {
      words = onValue.data()?["Words_map"];
    });
    setState(() {
      wordsMap = words;
    });
    ;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Online Word Competition",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 194, 164, 244),
      ),
      body: Container(
        alignment: Alignment.center,
        child: isLoading
            ? CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Question ${currentQuestionIndex + 1} of ${wordsMap.keys.length}",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 67, 67, 67),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 29,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 213, 200, 237),
                        borderRadius: BorderRadius.circular(13),
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
                              color: const Color.fromARGB(255, 102, 53, 186),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            wordsMap[wordsMap.keys
                                .elementAt(currentQuestionIndex)]["meaning"]!,
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Monospace",
                                color: const Color.fromARGB(221, 0, 0, 0),
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 39),
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 213, 200, 237),
                        borderRadius: BorderRadius.circular(90),
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
                              color: const Color.fromARGB(255, 99, 22, 241),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            wordsMap[wordsMap.keys
                                    .elementAt(currentQuestionIndex)]
                                ["question_form"]!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(221, 0, 0, 0),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
