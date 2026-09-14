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

// 1. የክፍል/ቁጥር (Room Code) ማስገቢያ ገጽ
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
    return Scaffold(
      appBar: AppBar(title: const Text('የግንኙነት ቁጥር ያስገቡ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ከሌላ ሰው ጋር ለመገናኘት የሚፈልጉትን ቁጥር (ለምሳሌ 12 ወይም 13) እዚህ ያስገቡ:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _roomController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'የቁጥር/የክፍል ኮድ (Room Code)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinRoom,
              child: const Text('ግባ (Join)'),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. የመልእክት ልውውጥ እና ኦንላይን ሁኔታ ማሳያ ገጽ
class ChatScreen extends StatefulWidget {
  final String roomCode;
  const ChatScreen({super.key, required this.roomCode});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String text = _messageController.text;
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('messages')
        .add({
      'message': text,
      'sender': 'ተጠቃሚ',
      'timestamp': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('ኮድ: ${widget.roomCode}'),
            const SizedBox(width: 15),
            // የሁለተኛው ሰው ኦንላይን መሆን የሚያሳይ (በቀጥታ ከሰርቨር የሚመጣ)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomCode)
                  .snapshots(),
              builder: (context, snapshot) {
                bool isOnline = false;
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>?;
                  isOnline = data?['isOnline'] ?? false;
                }
                return Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? 'ኦንላይን' : 'ኦፍላይን',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
                  return const Center(child: Text('ምንም መልእክቶች የሉም።'));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data['message'] ?? '',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'መልእክት ይጻፉ...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue, size: 30),
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
