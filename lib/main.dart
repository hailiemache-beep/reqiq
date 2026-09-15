import 'package:flutter/material.dart';

void main() {
  runApp(RaqiqApp());
}

class RaqiqApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ራቂቅ (Raqiq)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RaqiqLoginScreen(),
    );
  }
}

// 1. የመጀመሪያው የስልክ ቁጥር እና ኮድ ማስገቢያ ገጽ
class RaqiqLoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ራቂቅ - ግባ (Login)'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'እንኳን ወደ ራቂቅ መጡ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SizedBox(height: 30),
            TextField(
              decoration: InputDecoration(
                labelText: 'ስልክ ቁጥር ያስገቡ',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'የማረጋገጫ ኮድ (Code)',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: () {
                  // ቁልፉ ሲጫን ወደ ቻት ገጽ (Chat Screen) እንዲሄድ ይደረጋል
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RaqiqChatScreen()),
                  );
                },
                child: Text('ግባ (Login)', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. የመልእክት ልውውጥ (Chat) ገጽ
class RaqiqChatScreen extends StatefulWidget {
  @override
  _RaqiqChatScreenState createState() => _RaqiqChatScreenState();
}

class _RaqiqChatScreenState extends State<RaqiqChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = []; // መልእክቶች የሚቀመጡበት ዝርዝር

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _messages.add(_messageController.text);
        _messageController.clear(); // ጽሁፉን ከጻፈ በኋላ ሳጥኑን ባዶ ማድረግ
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('ራቂቅ ቻት'),
            SizedBox(width: 10),
            // ተጠቃሚው ኦንላይን መሆኑን የሚያሳይ አረንጓዴ ነጥብ (Online Status)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // የተላኩ እና የተጻፉ መልእክቶች የሚነበቡበት ክፍት ቦታ
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.all(8.0),
                  child: Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(_messages[index], style: TextStyle(fontSize: 16)),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // ኪቦርድ የሚመጣበት እና መልእክት የሚጻፍበት / የሚላክበት ቦታ
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'መልእክት ይጻፉ...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage, // መልእክቱን መላኪያ ትዕዛዝ
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
