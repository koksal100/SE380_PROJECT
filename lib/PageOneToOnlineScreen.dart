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
  int myScore=0;
  int opponentScore=0;
  late String languageCode;
  late Map<String, dynamic> wordsMap;
  int currentQuestionIndex = 0;
  String modOfJoiningRoom = "";
  bool showAnswer=false;
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int countdown = 30;
  late Timer _timer;
  bool isWordWinningScreen = false;
  String lastWinner="";
  String opponentNickname = "";

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
    }).then((onValue){
      _startCountdown();
      listenRoomInformations();
    });

    super.initState();
  }

  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        if(modOfJoiningRoom=="join"){
          increaseQuestionIndex();
        }
        setState(() {
          countdown = 30;
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
      final LanguageDocReferance = FirebaseFirestore.instance
          .collection('Languages')
          .doc(widget.language);

      await LanguageDocReferance.get().then((LanguageDocSnapshot) async {

        final data = LanguageDocSnapshot.data();
        if (data == null) {
          print("Hata: LanguageDocSnapshot.data() null döndü.");
          return;
        }else{
          print(data);
        }

        List<dynamic> waitingRoomsIds = data["WaitingRooms"];

        if(waitingRoomsIds.length==0){
          setState(() {
            roomId=generateUniqueId();
            modOfJoiningRoom="build";
          });
          LanguageDocReferance.update({"WaitingRooms":[roomId]});
          LanguageDocReferance.collection("Rooms").doc(roomId).set({});

        }else {
          setState(() {
            modOfJoiningRoom="join";
            roomId = waitingRoomsIds[0];
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
            "Users_map": {},
            "AttendanceNumber":1,
            "lastWinner":""
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
              widget.nickname: {"user_id":MyHomePageState.userId, "score": 0}
            }
          };
          currentRoomReferance.update({"Users_map": updatedDict});
        }).then((onValue) async {
          if (modOfJoiningRoom == "join") {
            LanguageDocReferance.get().then((onValue) async {

              List<dynamic> currentListOfInProgressRoomsIds=onValue.data()?["InProgressRooms"];
              List<dynamic> currentListOfWaitingRoomsIds=onValue.data()?["WaitingRooms"];
              currentListOfWaitingRoomsIds.remove(roomId);
              currentListOfInProgressRoomsIds.add(roomId);

              await currentRoomReferance.update({"AttendanceNumber":2});
              await LanguageDocReferance.update({"InProgressRooms":currentListOfInProgressRoomsIds,"WaitingRooms":currentListOfWaitingRoomsIds});

            });
          }
        });
      });

      await getWordsFromFirebase();
  }

  Future<void> getWordsFromFirebase() async {
    Map<String, dynamic> words = {};

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
      if (pattern[i] != '_' && pattern[i] != word[i]) {
        return false;
      }
    }

    return true;
  }

  void checkGuess()async{
    if(_formKey.currentState!.validate()){
      if(_controller.text.toLowerCase()==wordsMap[wordsMap.keys
          .elementAt(currentQuestionIndex)]
      ["what_word_is_displayed"]!.toString().toLowerCase()){

        final currentRoomReferance=FirebaseFirestore.instance
            .collection('Languages')
            .doc(widget.language)
            .collection('Rooms')
            .doc(roomId);

        await currentRoomReferance.get().then((currentRoomDocSnapshot)async{
          Map<String,dynamic> currentDictOfUsers=currentRoomDocSnapshot.data()?["Users_map"];
          int currentPoint=currentDictOfUsers[widget.nickname]['score'];
          currentDictOfUsers[widget.nickname]["score"]=currentPoint+50;
          currentRoomReferance.update({
            "Users_map":currentDictOfUsers,
            "lastWinner":lastWinner==widget.nickname?widget.nickname+" " : widget.nickname,
            "currentQuestionIndex":
            (currentRoomDocSnapshot.data()?
            ["currentQuestionIndex"]+1)});
        });


        _controller.clear();

      }else{
        print("yanlış cevap");
        print(wordsMap[wordsMap.keys
            .elementAt(currentQuestionIndex)]
        ["what_word_is_displayed"]!.toString().toLowerCase());
      }
    }
  }

  Future<void> waitFor2Participant() async {
    final CurrentRoomReferance=FirebaseFirestore.instance
        .collection('Languages')
        .doc(widget.language)
        .collection('Rooms')
        .doc(roomId);


    CurrentRoomReferance.snapshots().listen((onData){
      int AttendanceNumber=onData.data()?["AttendanceNumber"];
      if(AttendanceNumber==2){
        if(mounted){
          setState(() {
            countdown=30;
            isLoading=false;
            return;
          });
        }
      }
    });
  }

  void listenRoomInformations(){

    final CurrentRoomReferance=FirebaseFirestore.instance
        .collection('Languages')
        .doc(widget.language)
        .collection('Rooms')
        .doc(roomId);

      CurrentRoomReferance.snapshots().listen((onData){

      if(opponentNickname==""){
        onData.data()?["Users_map"].forEach((key, value) {
            if (key != widget.nickname) {
              setState(() {
                opponentNickname=key;
              });
            }
          });
      }

      var newWinner = onData.data()?["lastWinner"];
      if(newWinner!=lastWinner&&mounted){
        setState(() {
          isWordWinningScreen=true;
          lastWinner=newWinner;
          countdown=34;
          if(mounted) {
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

      if(mounted) {
        setState(() {
          currentQuestionIndex = onData.data()?["currentQuestionIndex"];
          myScore = onData.data()?["Users_map"][widget.nickname]["score"];
          if (opponentNickname != "") {
            opponentScore =
                onData.data()?["Users_map"][opponentNickname]["score"];
          }
        });
      }
    });

  }

  void showAnswerFunc(){
    setState(() {
      showAnswer=!showAnswer;
    });
  }

  void increaseQuestionIndex() async {
    final currentRoomReferance=FirebaseFirestore.instance
        .collection('Languages')
        .doc(widget.language)
        .collection('Rooms')
        .doc(roomId);

    await currentRoomReferance.get().then((currentRoomDocSnapshot)async{
      currentRoomReferance.update({
        "currentQuestionIndex":
        (currentRoomDocSnapshot.data()?
        ["currentQuestionIndex"]+1)});
    });
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
        body: Form(key: _formKey,
          child:  Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: isLoading
                ? CircularProgressIndicator()
                :isWordWinningScreen
              ? Center(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.purple.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${wordsMap[wordsMap.keys.elementAt(currentQuestionIndex-1)]["what_word_is_displayed"]}',
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

                : Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            Text(widget.nickname,style: TextStyle(fontWeight: FontWeight.bold),)
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              Icons.timer,
                              color:Color.fromARGB(255, 213, 200, 237),
                              size: 40,
                            ),
                            SizedBox(width: 8),

                            Text(
                              "$countdown",
                              style: TextStyle(
                                fontSize: 29,
                                fontWeight: FontWeight.bold,
                                color:Color.fromARGB(255, 102, 53, 186),
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
                                    fontWeight: FontWeight.bold,
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
                            Text(opponentNickname,style: TextStyle(fontWeight: FontWeight.bold),)
                          ],
                        ),
                      ],
                    )
                    ,
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
                                .elementAt(currentQuestionIndex)]["meaning"]?? " ",
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
                    SizedBox(height: 45,),
                    TextFormField(
                      validator: (value) {
                        print("validator çağrıldı");
                        if (value == null || value.isEmpty) {
                          return 'Empty guess is not valid!';
                        } else if (!isMatchingGuessWithActualWord(wordsMap[wordsMap.keys
                            .elementAt(currentQuestionIndex)]
                        ["question_form"]!,value)) {
                          return 'Your guess should be matching with given clues';
                        }
                        return null;
                      },
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: 'Enter your guess',
                        labelStyle: TextStyle(color: Colors.grey,fontWeight: FontWeight.bold),
                        prefixIcon: Icon(Icons.text_fields, color: Colors.grey),
                        suffixIcon: ElevatedButton(style:ButtonStyle(backgroundColor:WidgetStatePropertyAll(Color.fromARGB(255, 213, 200, 237))),onPressed:checkGuess, child: Text("Submit",style: TextStyle(fontSize :20,fontWeight: FontWeight.bold),)),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.purple, width: 4),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(39),
                          borderSide: BorderSide(color: Color.fromARGB(255, 213, 200, 237), width: 4),
                        ),
                      ),
                      style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16,fontFamily:"Monospace",letterSpacing: 1 ),
                    ),

                    //ElevatedButton(onPressed: showAnswerFunc, child: Text(showAnswer?"${wordsMap[wordsMap.keys
                    //  .elementAt(currentQuestionIndex)]["what_word_is_displayed"]}":"click here to show word"))
                  ],
                ),
              ),
            ),
          ),
        )


    );
  }

}



