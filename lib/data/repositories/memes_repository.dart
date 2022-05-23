import 'dart:convert';

import 'package:memogenerator/data/model/meme.dart';
import 'package:memogenerator/data/shared_preference_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';


class MemesRepository {

  final updater = PublishSubject<Null>();
  final SharedPreferenceData spData;

  static MemesRepository? _instance;
  // если не создан объект, то создаем и присваиваем
  factory MemesRepository.getInstance() =>
      _instance ??= MemesRepository._internal(SharedPreferenceData.getInstance());

  MemesRepository._internal(this.spData);


  // метод добавления в главный экран
  Future<bool> addToMemes(final Meme meme) async {
    // получаем сырой список memes, листы со стрингами
    final rawMemes = await spData.getMemes();
    // сохраняем нового героя
    rawMemes.add(json.encode(meme.toJson()));
    // // прокидываем событие об изменении хранилища
    return _setRawMemes(rawMemes);
  }

  // удаление по id
  Future<bool> removeFromMemes(final String id) async {
    // получаем мем по id, сырой список превратили в стринг
    final memes = await getMemes();
    // сохраняем новый мем
    memes.removeWhere((meme) => meme.id == id);
    // сохраняем
    return _setMemes(memes);
  }

  // отображение всего списка избранного на главном экране
  // при изменении данных запашивать данные у shared_Preferences
  // подписка на мемы
  Stream<List<Meme>> observeMemes() async* {
    // возвращаем значение в Stream подождав, от сюда _getMemes()
    yield await getMemes();
    await for (final _ in updater) {
      // приходит инфа в updater
      // отдаем текущее состояние хранилища
      yield await getMemes();
    }
  }


  Future<List<Meme>> getMemes() async {
    // получаем сырой список мемов, листы со стрингами
    final rawMemes = await spData.getMemes();
    // получаем мем по id, сырой список превратили в стринг
    return rawMemes
        .map((rawMeme) => Meme.fromJson(json.decode(rawMeme)))
        .toList();
  }



  // сохранение списка избранного в локальном хранилище
  // и его отображение на экране
  Future<Meme?> getMeme(final String id) async {
    // получаем meme
    final memes = await getMemes();
    return memes.firstWhereOrNull((meme) => meme.id == id);
  }

  Future<bool> _setMemes(final List<Meme> memes) async {
    final rawMemes = memes
        .map((meme) => json.encode(meme.toJson()))
        .toList();
    // сохраняем
    return _setRawMemes(rawMemes);
  }

  Future<bool> _setRawMemes(final List<String> rawMemes) {
    updater.add(null);
    return spData.setMemes(rawMemes);
  }






}
