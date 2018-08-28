import 'dart:async';
import 'dart:io';
import 'dart:convert';

final HOST = InternetAddress("192.168.0.4");
final PORT = 8080;

final TAG = "wxg";
var logger = Logger();

final API_MAP = ["user", "login"];

main() {
  startServer();
}

/// start the server.
void startServer() {
  HttpServer.bind(HOST, PORT).then((_server) {
    logger.d(
        TAG, 'Listening on http://${_server.address.address}:${_server.port}');

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
    res
      ..write('Received request ${request.method}: ${request.uri.path}')
      ..close();
  }
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
    res
      ..write('Received request ${request.method}: ${request.uri.path}')
      ..close();
  }
}

/**
 * handle the error.
 */
handleError(e) {
  logger.d(TAG, 'Exception in handleError: $e');
}

/**
 * the restful resopnse.
 */
void restfulResponse(HttpRequest request) async {
  var list = request.uri.path.split('/');
  list.removeWhere((value) => value == null || value.isEmpty);

  var url = list.firstWhere((value) {
    if (value != null) {
      return API_MAP.contains(value);
    } else {
      return false;
    }
  }, orElse: () {});

  if (url != null) {
    handleController(request, url);
  } else {
    defaultData(request);
  }
}

/**
 *
 */
void handleController(HttpRequest request, String url) {
  switch (url) {
    case "user":
      getUserData(request);
      break;

    default:
      defaultData(request);
      break;
  }
}

/**
 * get user data.
 */
void getUserData(HttpRequest request) {
  var user = User("zhangsan", "nova@1221.com");
  getResponseData(request, json.encode(user.toJson()));
}

/**
 * get default data.
 */
void defaultData(HttpRequest request) {
  try {
    var requestData = getRequestData(request);
    if (requestData != null) {
      requestData.then((value) {
        getResponseData(request, value);
      }, onError: handleError);
    } else {
      getResponseData(request);
    }
  } catch (e) {
    request.response
      ..write("Exception during file I/O: $e.")
      ..close();
  }
}

void getResponseData(HttpRequest request, [Object data]) {
  HttpResponse response = request.response;
  String encodedString;

  if (data != null && (data as String).isNotEmpty) {
    encodedString = data;
  } else {
    encodedString =
        json.encode({"name": "John Smith", "email": "john@example.com"});
  }

  response.headers.contentType =
      new ContentType("application", "json", charset: "utf-8");

  response
    ..write(encodedString)
    ..close();

  logger.d(TAG,
      "request path is ${request.uri.path}, request data is ${request.uri.data}, response data is \n$encodedString");
}

Future<String> getRequestData(HttpRequest request) async {
  try {
    var data = await request.transform(utf8.decoder).join();
    logger.d(TAG, "request data is : \n$data");
    return data;
  } catch (e) {
    logger.d(TAG, e);
    return null;
  }
}

class Logger {
  void d(String tag, Object object) =>
      print("${DateTime.now()} $tag d/ : $object");
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
