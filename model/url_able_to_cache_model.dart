class UrlAbleToCacheModel {
  final String keyUrl;
  Duration timeToAddBeforeExpired;

  UrlAbleToCacheModel({
    required this.keyUrl,
    required this.timeToAddBeforeExpired,
  });
}
