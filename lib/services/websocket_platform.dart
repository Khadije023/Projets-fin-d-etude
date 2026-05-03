// lib/services/websocket_platform.dart

import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectPlatformWebSocket(Uri uri) {
  return WebSocketChannel.connect(uri);
}
