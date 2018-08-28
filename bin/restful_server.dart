import 'dart:io';
import 'dart:convert';

final HOST = InternetAddress("192.168.0.4");
final PORT = 8080;

main() {
  startServer();
}

/// start the server.
void startServer() {
  HttpServer.bind(HOST, PORT).then((_server) {
    print('Listening on http://${_server.address.address}:${_server.port}');

    _server.listen((HttpRequest request) {
      switch (request.method) {
        case 'GET':
          handleGetRequest(request);
          break;
        case 'POST':
          handlePostRequest(request);
          break;
        default:
          defaultHandler(request);
          break;
      }
    }, onError: handleError); // listen() failed.
  }).catchError(handleError);
}

/**
 * handle the type of get request.
 */
void handleGetRequest(HttpRequest request) {
  HttpResponse res = request.response;

  addCorsHeaders(res);

  if (request.uri.path.startsWith('api', 1)) {
    restfulResponse(request);
  } else {
    res.write('Received request ${request.method}: ${request.uri.path}');
  }

  res.close();
}

/**
 * handle the type of post request.
 */
void handlePostRequest(HttpRequest request) {
  HttpResponse res = request.response;

  addCorsHeaders(res);

  if (request.uri.path.startsWith('api', 1)) {
    restfulResponse(request);
  } else {
    res.write('Received request ${request.method}: ${request.uri.path}');
  }

  res.close();
}

/**
 * handle the error.
 */
handleError(e) {
  print('Exception in handleError: $e');
}

/**
 * the restful resopnse.
 */
void restfulResponse(HttpRequest request) {
  HttpResponse response = request.response;

  response.headers.contentType =
      new ContentType("application", "json", charset: "utf-8");

  String encodedString =
      json.encode({"name": "John Smith", "email": "john@example.com"});

  response.write(encodedString); // Strings written will be UTF-8 encoded.

  print(request.toString());

  print(
      "request path is ${request.uri.path}, request data is ${request.uri.data}, response data is $encodedString");
}

//void printf(key, value) {
//  print("$key --- $value");
//}

class User {
  final String name;
  final String email;

  User(this.name, this.email);

  User.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        email = json['email'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
      };
}

/**
 *
 */
void addCorsHeaders(HttpResponse response) {
  response.headers.add('Access-Control-Allow-Origin', '*');
  response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
  response.headers.add('Access-Control-Allow-Headers',
      'Origin, X-Requested-With, Content-Type, Accept');
}

void defaultHandler(HttpRequest request) {
  var response = request.response;
  addCorsHeaders(response);
  response
    ..statusCode = HttpStatus.notFound
    ..write('Not found: ${request.method}, ${request.uri.path}')
    ..close();
}
