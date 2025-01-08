import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PageFour extends StatefulWidget {
  const PageFour({super.key});

  @override
  State<PageFour> createState() => _PageFourState();
}

class _PageFourState extends State<PageFour> {
  bool loading = true;
  List<Map<String, dynamic>> users = [];

  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      loading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy("score", descending: true)
          .get();

      setState(() {
        users = snapshot.docs.map((doc) {
          return {
            'name': doc.id,
            'score': doc['score'],
          };
        }).toList();
      });
    } catch (e) {
      print("Kullanıcı verileri alınırken hata oluştu: $e");
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    users.sort((a, b) => b['score'].compareTo(a['score']));
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Ranking',style: TextStyle(fontWeight: FontWeight.bold),)),
        backgroundColor: Colors.purple,
      ),
      body:
      loading
          ?
      Center(child: CircularProgressIndicator()):
      Container(
        color: Colors.deepPurple.shade50,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'User Rankings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      title: Text(
                        user['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                      subtitle: Text(
                        'Score: ${user['score']}',
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                      trailing: Icon(
                        Icons.star,
                        color: Colors.deepPurple.shade400,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
