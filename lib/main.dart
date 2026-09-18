import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RaqiqLoginScreen(),
    );
  }
}

// 1. መግቢያ (Login) ስክሪን
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
              'እንኳን ወደ ራቂቅ ቻት መጡ',
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
                labelText: 'የቻት ክፍል ኮድ (Room Code)',
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
                  Navigator.pushReplacement(
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
                    const SnackBar(content: Text('እባክዎ ስልክ እና የክፍል ኮድ በትክክል ያስገቡ!')),
                  );
                }
              },
              child: const Text('ውይይቱን ጀምር (Login)', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. የቻት (Chat) ስክሪን
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
        title: Text('ራቂቅ ቻት (ክፍል: ${widget.roomCode})'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.roomCode)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // ዳታ እስኪመጣ ድረስ ባዶ ግራጫ ስክሪን ሳይሆን ሎዲንግ እንዲያሳይ ተደርጓል
                if (snapshot.hasError) {
                  return Center(child: Text('ስህተት ተፈጥሯል: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  const Center(
                    child: Text('እስካሁን ምንም መልእክት የለም። የመጀመሪያውን ቴክስት ይላኩ!'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['sender'] == widget.userPhone;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[600] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['sender'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: isMe ? Colors.white : Colors.black87,
                              ),
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
          // የቴክስት መጻፊያ ሳጥን እና የላክ አዝራር
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'መልእክት ጻፍ...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
