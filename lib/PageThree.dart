import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PageThree extends StatefulWidget {
  const PageThree({Key? key}) : super(key: key);

  @override
  State<PageThree> createState() => _PageThreeState();
}

class _PageThreeState extends State<PageThree> {
  int correctAnswersGerman = 0;
  int incorrectAnswersGerman = 0;
  int correctAnswersEnglish = 0;
  int incorrectAnswersEnglish = 0;
  int correctAnswersFrench = 0;
  int incorrectAnswersFrench = 0;

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }


  void initStats(){
    SharedPreferences.getInstance().then((prefs){
      setState(() {
        correctAnswersGerman = (prefs.getStringList("correct_German")??[]).length;
        incorrectAnswersGerman = (prefs.getStringList("false_German")??[]).length;
        correctAnswersEnglish = (prefs.getStringList("correct_English")??[]).length;
        incorrectAnswersEnglish =  (prefs.getStringList("false_English")??[]).length;
        correctAnswersFrench =  (prefs.getStringList("correct_French")??[]).length;
        incorrectAnswersFrench =  (prefs.getStringList("false_French")??[]).length;
      });
    }).then((onValue){

    });
  }

  Future<void> loadStatistics() async {
    final random = Random();
    initStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Performance",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            buildLanguageStatistics(
                "German", correctAnswersGerman, incorrectAnswersGerman),
            const SizedBox(height: 20),
            buildLanguageStatistics(
                "English", correctAnswersEnglish, incorrectAnswersEnglish),
            const SizedBox(height: 20),
            buildLanguageStatistics(
                "French", correctAnswersFrench, incorrectAnswersFrench),
          ],
        ),
      ),
    );
  }

  Widget buildLanguageStatistics(String language, int correct, int incorrect) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$language Statistics",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Correct Answers: $correct"),
                Text("Incorrect Answers: $incorrect"),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: correct + incorrect > 0
                      ? correct / (correct + incorrect)
                      : 0,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
