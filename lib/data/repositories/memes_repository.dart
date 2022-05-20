import 'dart:convert';

import 'package:memogenerator/data/model/meme.dart';
import 'package:memogenerator/data/shared_preference_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MemesRepository {

  final updater = PublishSubject<Null>();
  final SharedPreferenceData spData;

  static MemesRepository? _instance;
  // если не создан объект, то создаем и присваиваем
  factory MemesRepository.getInstance() =>
      _instance ??= MemesRepository._internal(SharedPreferenceData.getInstance());

  MemesRepository._internal(this.spData);


  // метод добавления в избранное
  Future<bool> addToMemes(final Meme meme) async {
    // получаем сырой список героев, листы со стрингами
    final rawMemes = await spData.getMemes();
    // сохраняем нового героя
    rawMemes.add(json.encode(meme.toJson()));
    // // прокидываем событие об изменении хранилища
    updater.add(null);
    return spData.setMemes(rawMemes);
  }

  // удаление по id
  Future<bool> removeFromMemes(final String id) async {
    // получаем супергерой по id, сырой список превратили в стринг
    final memes = await _getMemes();
    // сохраняем нового героя
    memes.removeWhere((meme) => meme.id == id);
    // сохраняем
    return _setMemes(memes);
  }
  

  /* вспомогательные методы удаления */
  Future<List<Meme>> _getMemes() async {
    // получаем сырой список героев, листы со стрингами
    final rawMemes = await spData.getMemes();
    // получаем супергерой по id, сырой список превратили в стринг
    return rawMemes
        .map((rawMeme) => Meme.fromJson(json.decode(rawMeme)))
        .toList();
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

  /* КОНЕЦ методы удаления */

  // сохранение списка избранного в локальном хранилище
  // и его отображение на экране
  Future<Meme?> getMeme(final String id) async {
    // получаем супергероя
    final superheroes = await _getMemes();
    for (final superhero in superheroes) {
      if (superhero.id == id) {
        return superhero;
      }
    }
    return null;
  }

  // отображение всего списка избранного на главном экране
  // при изменении данных запашивать данные у shared_Preferences
  // подписка на супергероев
  Stream<List<Meme>> observeFavoriteMemes() async* {
    // возвращаем значение в Stream подождав, от сюда _getMemes()
    yield await _getMemes();
    await for (final _ in updater) {
      // приходит инфа в updater
      // отдаем текущее состояние хранилища
      yield await _getMemes();
    }
  }

  // для значка избранного. Есть ли сейчас этот герой в избранном или нет
  Stream<bool> observeIsFavorite(final String id) {
    return observeFavoriteMemes().map(
        (superheroes) => superheroes.any((superhero) => superhero.id == id));
  }
}
