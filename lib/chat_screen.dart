import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  // መልዕክቱን ወደ ፋየርቤዝ የሚልክ ፈንክሽን
  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('messages').add({
      'text': _controller.text,
      'createdAt': Timestamp.now(),
      'sender': 'user_id_or_name', // የላኪው ስም ወይም ID
    });

    _controller.clear(); // የጻፉትን ከቦክሱ ባዶ ያደርገዋል
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ራቂቅ ቻት')),
      body: Column(
        children: [
          // 1. ከፋየርቤዝ የሚመጡ መልዕክቶች የሚታዩበት ክፍል
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true, // አዳዲስ መልዕክቶች ከታች እንዲታዩ
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var messageData = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(messageData['text'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),

          // 2. ኪቦርዱን ተጠቅመን ጽሁፍ የምንጽፍበት እና መላኪያ ቦታ
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'መልዕክት ይጻፉ...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage, // ሲጫኑ መልዕክቱ ይላካል
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
