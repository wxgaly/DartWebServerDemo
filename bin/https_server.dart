import 'dart:io';
import "dart:isolate";

main() {
  SecurityContext context = new SecurityContext();
  var chain =
      Platform.script.resolve('certificates/server_chain.pem').toFilePath();
  var key = Platform.script.resolve('certificates/server_key.pem').toFilePath();
  context.useCertificateChain(chain);
  context.usePrivateKey(key, password: 'dartdart');
  HttpServer.bindSecure(InternetAddress("192.168.0.4"), 8080, context)
      .then((server) {
    server.listen((HttpRequest request) {
      request.response.write('Hello, world!');
      request.response.close();
    });
  });
}
