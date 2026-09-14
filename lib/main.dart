import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RaqiqChatApp());
}

class RaqiqChatApp extends StatelessWidget {
  const RaqiqChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ራቂቅ ቻት',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RoomJoinScreen(),
    );
  }
}

// 1. የክፍል/ግንኙነት ኮድ (Room Code) ማስገቢያ ገጽ
class RoomJoinScreen extends StatefulWidget {
  const RoomJoinScreen({super.key});

  @override
  State<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends State<RoomJoinScreen> {
  final TextEditingController _roomController = TextEditingController();

  void _joinRoom() {
    if (_roomController.text.trim().isEmpty) return;
    String roomCode = _roomController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(roomCode: roomCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String myId = DateTime.now().millisecondsSinceEpoch.toString();
    return Scaffold(
      appBar: AppBar(title: const Text('ከሌላ ሰው ጋር መገናኛ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ከተወሰነ ሰው ጋር ለመገናኘት የሚፈልጉትን ቁጥር (ለምሳሌ 12 ወይም 13) እዚህ ያስገቡ:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'የግንኙነት ቁጥር (Room Code)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinRoom,
              child: const Text('ወደ ውይይት ግባ'),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. መልእክት የሚላክበት እና የሚቀበልበት የውስጥ ሎጂክ ያለው የቻት ስክሪን
class ChatScreen extends StatefulWidget {
  final String roomCode;
  const ChatScreen({super.key, required this.roomCode});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  // ለእያንዳንዱ ተጠቃሚ የተለየ መለያ (ID) እንፈጥራለን (ማን የላከው መሆኑን ለመለየት)
  final String _userId = DateTime.now().millisecondsSinceEpoch.toString();

  // ----------------------------------------------------
  // [1] መልእክት ወደ ሰርቨር (Cloud Firestore) የመላክ ኮድ (እኛ ስንጽፍ)
  // ----------------------------------------------------
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String textToSend = _messageController.text.trim();
    _messageController.clear();

    try {
      // በሰርቨር ላይ ባለው የተለየ ሩም (Room Code) ውስጥ መልእክቱን እንመዘግባለን
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .collection('messages')
          .add({
        'message': textToSend,
        'senderId': _userId, // መልእክቱን የላከው ሰው መለያ
        'timestamp': FieldValue.serverTimestamp(), // የሰዓት ማህተም
      });
    } catch (e) {
      print('መልእክት በመላክ ላይ ስህተት ተፈጥሯል: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('የውይይት ክፍል: ${widget.roomCode}'),
      ),
      body: Column(
        children: [
          // ----------------------------------------------------
          // [2] ከሰርቨር የሚመጡ መልእክቶችን በቅጽበት ተቀብሎ የማሳየት ኮድ (ሰው ሲጽፍልን)
          // ----------------------------------------------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomCode)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('ምንም መልእክቶች የሉም። የመጀመሪያውን መልእክት ይጻፉ!'),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // አዳዲስ መልእክቶች ከታች እንዲመጡ ከታች ወደ ላይ ያሳያል
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    String messageText = data['message'] ?? '';
                    String senderId = data['senderId'] ?? '';

                    // እኛ የላካቸው መልእክቶች በቀኝ በኩል፣ ከሌላው ሰው የመጡት በግራ በኩል እንዲታዩ ይደረጋል
                    bool isMe = (senderId == _userId);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          messageText,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ----------------------------------------------------
          // [3] የጽሁፍ ማስገቢያ ሳጥን እና የመላኪያ ቁልፍ
          // ----------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'መልእክት እዚህ ይጻፉ...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue, size: 30),
                  onPressed: _sendMessage, // እዚህ ላይ ጫን ሲደረግ መልእክቱ ወደ ሰርቨር ይሄዳል
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
