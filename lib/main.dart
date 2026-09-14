import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RaqiqApp());
}

class RaqiqApp extends StatelessWidget {
  const RaqiqApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ረቂቅ ቻት አፕሊኬሽን',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // መልእክት ወደ ኔትወርክ ሰርቨር (Firebase) ለመላክ
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String textToSend = _messageController.text;
    _messageController.clear();

    try {
      await _firestore.collection('raqiq_network_chats').add({
        'message': textToSend,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': 'User', // እዚህ ጋር የተጠቃሚውን ስም ወይም መታወቂያ ማድረግ ይቻላል
      });
    } catch (e) {
      debugPrint("መልእክት በመላክ ላይ ስህተት ተፈጥሯል: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ረቂቅ ቻት አፕሊኬሽን (በኔትወርክ)'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // ከኔትወርክ የሚመጡ መልእክቶችን በቅጽበት (Real-time) ለመቀበል እና ለማሳየት
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('raqiq_network_chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('ግንኙነት ላይ ስህተት ተፈጥሯል'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chatDocs = snapshot.data!.docs;

                if (chatDocs.isEmpty) {
                  return const Center(child: Text('ምንም መልእክት የለም። ማውራት ይጀምሩ!'));
                }

                return ListView.builder(
                  reverse: true, // አዲስ መልእክት ከታች እንዲመጣ
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chatData = chatDocs[index].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 12.0),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          chatData['message'] ?? '',
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1.0),
          // መልእክት መጻፊያ ክፍል
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'መልእክት ይጻፉ...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
