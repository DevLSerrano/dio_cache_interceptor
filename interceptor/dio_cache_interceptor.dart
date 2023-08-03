import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../hive/hive_controller.dart';
import 'model/url_able_to_cache_model.dart';

const cacheDateExpireKey = 'dateExpireCache';
const cacheIsFromCacheKey = 'isFromCache';

class DioHiveCacheInterceptor extends Interceptor {
  DioHiveCacheInterceptor();

  final methodsAllowedToCache = ['GET', 'POST'];

  final listOfUrlThatCanCache = [
    UrlAbleToCacheModel(
      keyUrl: 'homeHighLight',
      timeToAddBeforeExpired: const Duration(days: 1),
    ),
    UrlAbleToCacheModel(
      keyUrl: 'products',
      timeToAddBeforeExpired: const Duration(days: 1),
    ),
  ];

  Map<String, dynamic> updateMapInfoToLogger(Map<String, dynamic> cacheData) {
    cacheData[cacheIsFromCacheKey] =
        'True - Valid until ${cacheData[cacheDateExpireKey]}';
    return cacheData;
  }

  Map<String, dynamic> addKeyDateExpireToCache(
    Map<String, dynamic> cacheData,
    Duration timeToAddBeforeExpired,
  ) {
    cacheData[cacheDateExpireKey] =
        DateTime.now().add(timeToAddBeforeExpired).toString();
    return cacheData;
  }

  bool cacheTimeIsValid(Map<String, dynamic> cacheData) {
    return DateTime.tryParse(cacheData[cacheDateExpireKey] ?? '')
            ?.isAfter(DateTime.now()) ??
        false;
  }

  (String keyUrl, String bodyUrlKey) buildBodyUrlKey(RequestOptions options) {
    final keyUrl = options.path.split('/').last;
    final bodyUrlKey =
        '$keyUrl/${options.method == 'GET' ? jsonEncode(options.queryParameters) : jsonEncode(options.data ?? <String, dynamic>{})}';

    return (keyUrl, bodyUrlKey);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!methodsAllowedToCache.contains(options.method)) {
      handler.next(options);
    }

    final (keyUrl, bodyUrlKey) = buildBodyUrlKey(options);
    final existThisKeyUrl = listOfUrlThatCanCache
            .indexWhere((element) => element.keyUrl == keyUrl) !=
        -1;

    if (existThisKeyUrl) {
      final hiveBox = await HiveController.instance.getHiveBox;
      final cacheData = jsonDecode(hiveBox.get(bodyUrlKey) ?? '{}')
              as Map<String, dynamic>? ??
          {};

      if (cacheTimeIsValid(cacheData)) {
        return handler.resolve(
          Response(
            data: updateMapInfoToLogger(cacheData),
            requestOptions: options,
          ),
        );
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final (keyUrl, bodyUrlKey) = buildBodyUrlKey(response.requestOptions);
    final indexUrlAbleToCache =
        listOfUrlThatCanCache.indexWhere((element) => element.keyUrl == keyUrl);

    if (response.statusCode == 200 && indexUrlAbleToCache != -1) {
      final hiveBox = await HiveController.instance.getHiveBox;
      await hiveBox.put(
        bodyUrlKey,
        jsonEncode(
          addKeyDateExpireToCache(
            response.data as Map<String, dynamic>,
            listOfUrlThatCanCache[indexUrlAbleToCache].timeToAddBeforeExpired,
          ),
        ),
      );
    }

    handler.next(response);
  }
}
