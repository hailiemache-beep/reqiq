import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ፋየርቤዝ በትክክል እንዲነሳ ማድረግ
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const RaqiqApp());
}

class RaqiqApp extends StatelessWidget {
  const RaqiqApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ራቂቅ ቻት አፕ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RaqiqLoginScreen(),
    );
  }
}

// ==========================================================
// 1. የሎጊን (Login) ስክሪን ክፍል
// ==========================================================
class RaqiqLoginScreen extends StatefulWidget {
  const RaqiqLoginScreen({Key? key}) : super(key: key);

  @override
  State<RaqiqLoginScreen> createState() => _RaqiqLoginScreenState();
}

class _RaqiqLoginScreenState extends State<RaqiqLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ራቂቅ - መግቢያ (Login)'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'እንኳን ወደ ራቂቅ መጡ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'ስልክ ቁጥር ያስገቡ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _roomCodeController,
              decoration: const InputDecoration(
                labelText: 'የመጋገሪያ ኮድ (Room Code)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                String phone = _phoneController.text.trim();
                String roomCode = _roomCodeController.text.trim();

                if (phone.isNotEmpty && roomCode.isNotEmpty) {
                  // ወደ ቻት ስክሪን መረጃዎችን ይዞ ማለፍ
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RaqiqChatScreen(
                        roomCode: roomCode,
                        userPhone: phone,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('እባክዎ ስልክ እና ኮድ በትክክል ያስገቡ!')),
                  );
                }
              },
              child: const Text('ግባ (Login)', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// 2. የቻት (Chat) ስክሪን ክፍል
// ==========================================================
class RaqiqChatScreen extends StatefulWidget {
  final String roomCode;
  final String userPhone;

  const RaqiqChatScreen({
    Key? key,
    required this.roomCode,
    required this.userPhone,
  }) : super(key: key);

  @override
  State<RaqiqChatScreen> createState() => _RaqiqChatScreenState();
}

class _RaqiqChatScreenState extends State<RaqiqChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  // መልእክት ወደ ፋየርቤዝ የሚልክበት פונקشن
  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      String messageText = _messageController.text.trim();
      _messageController.clear();

      try {
        await FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(widget.roomCode)
            .collection('messages')
            .add({
          'text': messageText,
          'sender': widget.userPhone,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error sending message: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ራቂቅ ቻት (ኮድ: ${widget.roomCode})'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // መልእክቶች የሚታዩበት ክፍል
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
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
                    child: Text('እስካሁን ምንም መልእክት የለም። የመጀመሪያውን መልእክት ይላኩ!'),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // አዳዲስ መልእክቶች ከታች እንዲደረደሩ
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['sender'] == widget.userPhone;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['sender'] ?? '',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              data['text'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ኪቦርዱ ስክሪኑን እንዳይደብቀው እና መጻፊያው ከታች እንዲሆን የተደረገበት ክፍል
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 8.0,
              right: 8.0,
              top: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
