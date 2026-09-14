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
      home: const RoomJoinScreen(),
    );
  }
}

// 1. መጀመሪያ ሁለቱ ሰዎች የሚገናኙበትን ቁጥር (Room ID) የሚገቡበት ገጽ
class RoomJoinScreen extends StatefulWidget {
  const RoomJoinScreen({Key? key}) : super(key: key);

  @override
  State<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends State<RoomJoinScreen> {
  final TextEditingController _roomController = TextEditingController();

  void _joinRoom() {
    String roomCode = _roomController.text.trim();
    if (roomCode.isEmpty) return;

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
      appBar: AppBar(
        title: const Text('ረቂቅ - የቻት ክፍል መግቢያ'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ከሌላው ሰው ጋር ለመገናኘት የሚመሳሰለውን ቁጥር (ለምሳሌ 12) ያስገቡ',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _roomController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'የክፍል ቁጥር (Room Code, e.g. 12)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinRoom,
              child: const Text('ወደ ቻት ግባ'),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. እርስ በእርስ መልእክት የሚጻጻፉበት ትክክለኛ የቻት ገጽ
class ChatScreen extends StatefulWidget {
  final String roomCode;
  const ChatScreen({Key? key, required this.roomCode}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String textToSend = _messageController.text;
    _messageController.clear();

    try {
      await _firestore
          .collection('rooms')
          .doc(widget.roomCode)
          .collection('chats')
          .add({
        'message': textToSend,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("ስህተት ተፈጥሯል: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ክፍል: ${widget.roomCode}'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('rooms')
                  .doc(widget.roomCode)
                  .collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('ምንም መልእክት የለም። ማውራት ይጀምሩ!'));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
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
                          data['message'] ?? '',
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
