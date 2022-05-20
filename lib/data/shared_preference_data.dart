import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceData {

  static const memeKey = "meme_key";
  static SharedPreferenceData? _instance;

  factory SharedPreferenceData.getInstance() => _instance ??= SharedPreferenceData._internal();

  SharedPreferenceData._internal();

  Future<bool> setMemes(final List<String> memes) async {
    final sp = await SharedPreferences.getInstance();
    // прокидываем событие об изменении хранилища
    final result = sp.setStringList(memeKey, memes);
    return result;
  }


  Future<List<String>> getMemes() async {
    final sp = await SharedPreferences.getInstance();
    // получаем сырой список героев, листы со стрингами
    return sp.getStringList(memeKey) ?? [];
  }

}