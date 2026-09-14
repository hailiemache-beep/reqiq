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
      title: 'ራቂቅ - ቻት አፕሊኬሽን',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RoomJoinScreen(),
    );
  }
}

// 1. የክፍል ኮድ (Room Code) መቀላቀያ ስክሪን
class RoomJoinScreen extends StatefulWidget {
  const RoomJoinScreen({super.key});

  @override
  State<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends State<RoomJoinScreen> {
  final TextEditingController _roomController = TextEditingController();

  void _joinRoom() {
    String roomCode = _roomController.text.trim();
    if (roomCode.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(roomCode: roomCode),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ራቂቅ - የውይይት ክፍል መቀላቀያ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _roomController,
              enabled: true,
              readOnly: false,
              decoration: const InputDecoration(
                hintText: 'የክፍል ኮድ ያስገቡ...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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

// 2. የውይይት (Chat) እና የመልዕክት መላላኪያ ስክሪን
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

    String messageText = _messageController.text;
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .collection('messages')
        .add({
      'text': messageText,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // ኪቦርዱ ሲመጣ ስክሪኑ ተስተካክሎ ቦታ እንዲሰጥ
      appBar: AppBar(
        title: Text('የውይይት ክፍል: ${widget.roomCode}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomCode)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('እስካሁን ምንም መልዕክት የለም። መልዕክት ጽፈው ይቀበሉ!'),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(data['text'] ?? ''),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 8.0,
              right: 8.0,
              top: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: true, // ኪቦርዱ እንድመጣ እና ግራጫ ሆኖ እንዳይቀር
                    readOnly: false,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      hintText: 'መልዕክት ጽፈው ይቀበሉ...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
