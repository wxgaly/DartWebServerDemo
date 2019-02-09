import 'dart:io';
import 'dart:async';

Future main() async {
  var server = await HttpServer.bind(
    InternetAddress("192.168.31.229"),
    8080,
  );
  print('Listening on http://${server.address.address}:${server.port}');

  await for (HttpRequest request in server) {
    request.response
      ..write('''
      <html>
          <title>sdads</title>
          <body alink="这是获取到的数据">
            Hello, gdsfedv!
          </body>
      </html>
      ''')
      ..close();
  }
}
