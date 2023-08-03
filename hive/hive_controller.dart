import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class HiveController {
  static HiveController? _instance;
  Box? _box;
  HiveController._();

  static HiveController get instance {
    _instance ??= HiveController._();
    return _instance!;
  }

  Future<Box> get getHiveBox async {
    final pathBox = await getTemporaryDirectory();
    _box ??= await Hive.openBox(
      'sygpoint_cache',
      path: pathBox.path,
    );
    return _box!;
  }
}
