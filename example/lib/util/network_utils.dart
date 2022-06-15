import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_aliplayer_example/config.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart' as crypto;

class NetWorkUtils {
  static final NetWorkUtils _instance = NetWorkUtils._privateConstructor();

  static NetWorkUtils get instance {
    return _instance;
  }

  //针对原宇宙项目  签名key写死
  static const String _SIGN_KEY = "juR1E8ayHMkouxNX5va9YTsMOw2iJbzb2el\$EcbVf@SsV2JInjfwnUP2\%wenu\^O\!";

  static Dio _dio;

  NetWorkUtils._privateConstructor() {
    if (_dio == null) {
      _dio = Dio();
      _dio.options.connectTimeout = 5000;
      _dio.options.receiveTimeout = 5000;
      //增加请求头
      var headMap = HashMap<String, dynamic>();
      headMap["appVersion"] = "3.1.1";
      headMap["appType"] = "android";
      headMap["appName"] = "Meta";
      headMap["deviceToken"] = Uuid().v1().toString();
      _dio.options.headers.addAll(headMap);
      _dio.options.baseUrl = HttpConstant.DETOK_ONLINE_HTTP_HOST;
    }
  }

  void getHttp(String url,
      {Map<String, dynamic> params,
      Function successCallback,
      Function errorCallback}) async {
    Response response = await _dio.get(url, queryParameters: params);
    Map<String, dynamic> data = response.data;
    if (data.isNotEmpty && data['result'] == 'true') {
      successCallback(data['data']);
    } else {
      errorCallback(data);
    }
  }

  void postHttp(String url, {Map<String, dynamic> params, Function successCallback, Function errorCallback}) async {
    //创建临时map
    var tempMap = new LinkedHashMap<String, dynamic>();
    //进行参数处理
    String appTimeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    //同一次请求，生成一个，用字段存储一下，不要用一次调一次。
    String appNonce = new Uuid().v1().toString().replaceAll("-", "");
    //先增加2个参数
    tempMap["appNonce"] = appNonce;
    tempMap["appTimeStamp"] = appTimeStamp;
    //存储参数字符串
    StringBuffer paramsString = new StringBuffer();
    //先拼接前2个参数
    tempMap.forEach((key, value) {
      paramsString..write(key)..write("=")..write(value)..write("&");
    });
    //在拼接其他参数
    params.forEach((key, value) {
      if (value != null) {
        //将参数有序的添加到
        tempMap[key] = value;
        paramsString..write(key)..write("=")..write(value)..write("&");
      }
    });
    paramsString
      ..write("signSercetKey")
      ..write("=")
      ..write(_SIGN_KEY)
      ..write(appNonce);
    var appSign = generateMd5(paramsString.toString());
    tempMap["appSign"] = appSign;
    Response response = await _dio.post(url, data: json.encode(tempMap));
    Map<String, dynamic> data = response.data;
    if (data.isNotEmpty) {
      successCallback(data['data']);
    } else {
      errorCallback(data);
    }
  }

  Future<Map> getHttpFuture(String url, {Map<String, String> params}) async {
    Response response = await _dio.get(url, queryParameters: params);
    Map<String, dynamic> data = response.data;
    if (data.isNotEmpty && data['result'] == 'true') {
      return Future.value(data['data']);
    } else {
      return Future.error("$url request error");
    }
  }

  /// 计算md5
  String generateMd5(String input) {
    return crypto.md5.convert(utf8.encode(input)).toString();
  }

}
