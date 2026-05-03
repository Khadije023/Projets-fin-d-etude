import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class DiscussionAvecDocteurPage extends StatefulWidget {
  final String roomName;
  final WebSocketChannel channel;

  DiscussionAvecDocteurPage({super.key, required this.roomName})
      : channel = WebSocketChannel.connect(
          Uri.parse('ws://192.168.1.122:8000/ws/chat/$roomName/'),
        );

  @override
  DiscussionAvecDocteurPageState createState() =>
      DiscussionAvecDocteurPageState();
}

class DiscussionAvecDocteurPageState extends State<DiscussionAvecDocteurPage> {
  final TextEditingController _controller = TextEditingController();

  void _envoyerMessage() {
    if (_controller.text.isNotEmpty) {
      widget.channel.sink.add(json.encode({
        'message': _controller.text,
      }));
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discussion avec le Docteur'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: widget.channel.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  return ListView(
                    children: [
                      ListTile(
                        title: Text(snapshot.data['message']),
                      ),
                    ],
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _envoyerMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
