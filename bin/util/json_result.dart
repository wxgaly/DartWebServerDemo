class JSONResult {
  int status;
  String msg;
  dynamic data;

  JSONResult(this.status, this.msg, this.data);

  JSONResult.ok(dynamic data)
      : this.status = Status.OK,
        this.msg = "OK",
        this.data = data;

  JSONResult.errorMessage(int code, String msg)
      : this.status = code,
        this.msg = msg,
        this.data = '';

  JSONResult.errorException(String msg)
      : this.status = Status.EXCEPTION,
        this.msg = msg,
        this.data = '';

  Map<String, dynamic> toJson() => {'status': status, 'msg': msg, 'data': data};
}

class Status {
  /**
   *正常
   */
  static const OK = 0;

  /**
   * 未知异常
   */
  static const EXCEPTION = 10000;

  /**
   * 用户名或密码错误
   */
  static const USERNAME_OR_PASSWORD_ERROR = 10001;

  /**
   * 用户名重复
   */
  static const USERNAME_IS_REPEAT = 10002;

  /**
   * 用户名密码为空
   */
  static const USERNAME_OR_PASSWORD_IS_NULL = 10003;
}

class Message {
  static const OK = "成功";
  static const EXCEPTION = "未知异常";
  static const USERNAME_OR_PASSWORD_ERROR = "用户名或密码错误";
  static const USERNAME_IS_REPEAT = "用户名重复";
  static const USERNAME_OR_PASSWORD_IS_NULL = "用户名密码为空";
}
