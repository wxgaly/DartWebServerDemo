import 'dart:async';
import 'dart:io';

File targetFile = new File('index.html');

Future main() async {
  var server;

  try {
    server = await HttpServer.bind(InternetAddress("192.168.0.4"), 4044);
  } catch (e) {
    print("Couldn't bind to port 4044: $e");
    exit(-1);
  }

  await for (HttpRequest req in server) {
    if (await targetFile.exists()) {
      print("Serving ${targetFile.path}.");
      req.response.headers.contentType = ContentType.HTML;
      try {
        await targetFile.openRead().pipe(req.response);
      } catch (e) {
        print("Couldn't read file: $e");
        exit(-1);
      }
    } else {
      print("Can't open ${targetFile.path}.");
      req.response
        ..statusCode = HttpStatus.NOT_FOUND
        ..close();
    }
  }
}