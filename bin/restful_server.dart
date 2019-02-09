import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:http_server/http_server.dart';

import 'util/json_result.dart';


final HOST = InternetAddress("192.168.31.229");
final PORT = 9000;

final TAG = "wxg";
var logger = Logger();

const DART_SESSION_TAG = "DartSession";

const USER = "user";
const LOGIN = "login";
const LOGOUT = "logout";
const AUTH = "auth";
const API_MAP = [USER, LOGIN, AUTH, LOGOUT];

final loginUser =
    User("wxg", "email", "wxg", "e10adc3949ba59abbe56e057f20f883e");
var isLogin = false;
var server;

main() {
  startServer();
}

/// start the server.
void startServer()  {
  server = HttpServer.bind(HOST, PORT).then((_server) {
    logger.d(
        TAG, 'Listening on http://${_server.address.address}:${_server.port}');

    _server.listen((HttpRequest request) async {
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
Future handleGetRequest(HttpRequest request) async {
  HttpResponse res = request.response;

  addCorsHeaders(res);

  if (request.uri.path.startsWith('api', 1)) {
    restfulResponse(request);
  } else {
    if (server != null) {
      var pathToBuild = join(dirname(Platform.script.toFilePath()));

      var staticFiles = new VirtualDirectory(pathToBuild);
      staticFiles.allowDirectoryListing = true; /*1*/
      staticFiles.directoryHandler = (dir, request) /*2*/ {
        var indexUri = new Uri.file(dir.path).resolve('index.html');
        staticFiles.serveFile(new File(indexUri.toFilePath()), request); /*3*/
      };
      staticFiles.serveRequest(request);
    } else {
      responseWrite(
          res, 'Received request ${request.method}: ${request.uri.path}');
    }
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
    responseWrite(
        res, 'Received request ${request.method}: ${request.uri.path}');
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
    case USER:
      getUserData(request);
      break;

    case LOGIN:
      login(request);
      break;

    case AUTH:
      auth(request);
      break;

    case LOGOUT:
      logout(request);
      break;

    default:
      defaultData(request);
      break;
  }
}

/**
 * logout api.
 */
void logout(HttpRequest request) {
  responseData(request, (value) {
    try {
      var user = User.fromJson(json.decode(value));
      logger.d(TAG, "${user.username}");
      if (user.username == loginUser.username) {
        isLogin = false;
      }
    } catch (e) {
      print(e);
      isLogin = false;
    }
    return json.encode(JSONResult.ok(isLogin).toJson());
  });
}

/**
 * auth api.
 */
void auth(HttpRequest request) {
  responseData(
      request, (value) => json.encode(JSONResult.ok(isLogin).toJson()));
}

/**
 * login data.
 */
void login(HttpRequest request) {
  responseData(request, (value) {
    try {
      var user = User.fromJson(json.decode(value));
      logger.d(TAG, user.password);
      if (user.username == loginUser.username &&
          user.password == loginUser.password) {
        isLogin = true;
        value = json.encode(JSONResult.ok(user).toJson());
      } else {
        isLogin = false;
        value = json.encode(JSONResult.errorMessage(
                Status.USERNAME_OR_PASSWORD_ERROR,
                Message.USERNAME_OR_PASSWORD_ERROR)
            .toJson());
      }
    } catch (e) {
      print(e);
      value = json.encode(JSONResult.errorException(e.toString()).toJson());
    }

    return value;
  });
}

/**
 * get user data.
 */
void getUserData(HttpRequest request) {
  var user = User("zhangsan", "nova@1221.com", "111", "222");
  getResponseData(request, json.encode(user.toJson()));
}

void responseData(HttpRequest request, [Object f(dynamic data)]) {
  try {
    handleSession(request);
    var requestData = getRequestData(request);
    if (requestData != null) {
      requestData.then((value) {
        if (f != null) {
          value = f(value);
        }
        getResponseData(request, value);
      }, onError: handleError);
    } else {
      getResponseData(request);
    }
  } catch (e) {
    responseError(request.response, e);
  }
}

void handleSession(HttpRequest request) {
  var session = request.session;
  logger.d(TAG, "id is ${session.id}");
  if (session.containsKey(DART_SESSION_TAG)) {
    session.forEach((key, value) {
      logger.d(TAG, "key is $key, value is $value");
    });
  } else {
    session.addEntries([MapEntry(DART_SESSION_TAG, DART_SESSION_TAG)]);
  }
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
    responseError(request.response, e);
  }
}

void responseError(HttpResponse response, Exception e) {
  responseWrite(
      response,
      json.encode(JSONResult.errorException("Exception " "during file I/O: $e.")
          .toJson()));
}

void responseWrite(HttpResponse response, String data) {
  response
    ..write(data)
    ..close();
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

  responseWrite(response, encodedString);

  logger.d(TAG,
      "request path is ${request.uri.path}, request data is ${request.uri.data}, response data is \n$encodedString");
}

Future<String> getRequestData(HttpRequest request) async {
  try {
    var data = await request.transform(utf8.decoder).join();
    logger.d(TAG, "request data is : \n$data");
    data = getJsonData(data);
    return data;
  } catch (e) {
    logger.d(TAG, e);
    return null;
  }
}

String getJsonData(String data) {
  if (data == null ||
      (data.startsWith('{') && data.endsWith('}')) ||
      (data.startsWith('[') && data.endsWith(']'))) {
    return data;
  } else {
    var list = data.split('&');
    if (list == null || list.isEmpty) {
      return null;
    } else {
      var sb = StringBuffer();
      sb.write('{');

      for (int i = 0; i < list.length; i++) {
        var value = list[i];
        var sp = value.split('=');
        if (i == list.length - 1) {
          if (sp != null && sp.isNotEmpty) {
            sb.write('''"${sp[0]}" : "${sp[1]}"''');
          }
          break;
        }
        if (sp != null && sp.isNotEmpty) {
          sb.write('''"${sp[0]}" : "${sp[1]}", ''');
        }
      }

      sb.write('}');
      logger.d(TAG, sb.toString());
      return sb.toString();
    }
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
  final String username;
  final String password;

  User(this.name, this.email, this.username, this.password);

  User.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        email = json['email'],
        username = json['username'],
        password = json['password'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'username': username,
        'password': password,
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
  response.statusCode = HttpStatus.notFound;
  responseWrite(response, 'Not found: ${request.method}, ${request.uri.path}');
}

// md5 加密
String generateMd5(String data) {
  var content = new Utf8Encoder().convert(data);
  var digest = md5.convert(content);
  return hex.encode(digest.bytes);
}
