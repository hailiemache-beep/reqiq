import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  // መልእክት ወደ ፋየርቤዝ መላኪያ ኮድ
  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('messages').add({
      'text': _controller.text,
      'createdAt': Timestamp.now(),
      'sender': 'ተጠቃሚ', // እዚህ ጋር የሚፈልጉትን ስም ወይም መለያ ማስገባት ይቻላል
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ራቂቅ ቻት'),
      ),
      body: Column(
        children: [
          // 1. የመልእክቶች መደብ (ListView) የሚታይበት ክፍል
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // አዲስ መልእክት ከታች እንዲሆን
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final messageData = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(messageData['text'] ?? ''),
                      subtitle: Text(messageData['sender'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),

          // 2. ኪቦርዱ እና ቴክስት መጻፊያው ሳጥን የሚቀመጡበት የታችኛው ክፍል
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'መልእክት ጻፍ...',
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
