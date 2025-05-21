import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 1234);
  print('WebSocket Server running on ws://${server.address.address}:${server.port}');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocket socket = await WebSocketTransformer.upgrade(request);
      print('Client connected');

      Timer.periodic(Duration(seconds: 2), (timer) {
        double temp = 20 + Random().nextDouble() * 10; // สุ่ม 20 - 30 องศา
        String jsonData = jsonEncode({
          'temperature': temp.toStringAsFixed(2),
          'timestamp': DateTime.now().toIso8601String()
        });
        socket.add(jsonData);
      });

      socket.done.then((_) {
        print('Client disconnected');
      });
    } else {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    }
  }
}
