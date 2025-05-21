import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TempPage(),
    );
  }
}

class TempPage extends StatefulWidget {
  const TempPage({super.key});
  @override
  State<TempPage> createState() => _TempPageState();
}

class _TempPageState extends State<TempPage> {
  WebSocketChannel? _channel;
  String _temperature = 'รอการเชื่อมต่อ...';
  String _time = '';
  bool _connected = false;
  Timer? _reconnectTimer;
  final String _url = 'ws://192.168.104.160:1234'; // ใช้ IP จริงแทน localhost บนมือถือ

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() async {
    try {
      final socket = await WebSocket.connect(_url);
      _channel = IOWebSocketChannel(socket);

      setState(() {
        _connected = true;
        _temperature = 'เชื่อมต่อสำเร็จ!';
      });

      _channel!.stream.listen(
        (data) {
          var decoded = jsonDecode(data);
          setState(() {
            _temperature = "${decoded['temperature']} °C";
            _time = decoded['timestamp'];
          });
        },
        onDone: _onConnectionLost,
        onError: (e) {
          print('WebSocket error: $e');
          _onConnectionLost();
        },
        cancelOnError: true,
      );

    } catch (e) {
      print('เชื่อมต่อไม่สำเร็จ: $e');
      _onConnectionLost();
    }
  }

  void _onConnectionLost() {
    if (_connected) {
      setState(() {
        _connected = false;
        _temperature = 'เชื่อมต่อหลุด...';
        _time = '';
      });
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('พยายามเชื่อมต่อใหม่...');
      _connectWebSocket();
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('อุณหภูมิห้อง')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _connected ? Icons.cloud_done : Icons.cloud_off,
              size: 64,
              color: _connected ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _temperature,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 10),
            Text(
              _time,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
