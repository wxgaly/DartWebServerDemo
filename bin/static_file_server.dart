// Type localhost:4048 into your browser.
// This server returns the contents of index.html for all requests.

import 'dart:async';
import 'dart:io';
import 'package:http_server/http_server.dart';
import 'package:path/path.dart';

Future main() async {
  var pathToBuild = join(dirname(Platform.script.toFilePath()));

  var staticFiles = new VirtualDirectory(pathToBuild);
  staticFiles.allowDirectoryListing = true; /*1*/
  staticFiles.directoryHandler = (dir, request) /*2*/ {
    var indexUri = new Uri.file(dir.path).resolve('index.html');
    staticFiles.serveFile(new File(indexUri.toFilePath()), request); /*3*/
  };

  var server = await HttpServer.bind(InternetAddress("192.168.0.4"), 4048);
  print('Listening on port 4048');
  await server.forEach(staticFiles.serveRequest); /*4*/
}