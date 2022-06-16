import 'dart:convert';

import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/shared_preference_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

class TemplatesRepository {
  final updater = PublishSubject<Null>();
  final SharedPreferenceData spData;

  static TemplatesRepository? _instance;
  // если не создан объект, то создаем и присваиваем
  factory TemplatesRepository.getInstance() => _instance ??=
      TemplatesRepository._internal(SharedPreferenceData.getInstance());

  TemplatesRepository._internal(this.spData);

  // метод добавления в главный экран
  Future<bool> addToTemplates(final Template newTemplate) async {
    // получаем сырой список templates, листы со стрингами
    final templates = await getTemplates();
    // получение доступа к id существующего мема и сравниваем с новым
    final templateIndex = templates.indexWhere((template) => template.id == newTemplate.id);
    // если нет мема, то добавляем его
    if (templateIndex == -1) {
      // возвращаем старые мемы и новые
      templates.add(newTemplate);
    } else {
      templates.removeAt(templateIndex);
      templates.insert(templateIndex, newTemplate);
    }

    // возвращаем все мемы
    return _setTemplates(templates);
  }

  // удаление по id
  Future<bool> removeFromTemplates(final String id) async {
    // получаем мем по id, сырой список превратили в стринг
    final templates = await getTemplates();
    // удаляем новый мем
    templates.removeWhere((template) => template.id == id);
    // сохраняем
    return _setTemplates(templates);
  }

  // отображение всего списка избранного на главном экране
  // при изменении данных запашивать данные у shared_Preferences
  // подписка на мемы
  Stream<List<Template>> observeTemplates() async* {
    // возвращаем значение в Stream подождав, от сюда _getTemplates()
    yield await getTemplates();
    await for (final _ in updater) {
      // приходит инфа в updater
      // отдаем текущее состояние хранилища
      yield await getTemplates();
    }
  }

  Future<List<Template>> getTemplates() async {
    // получаем сырой список мемов, листы со стрингами
    final rawTemplates = await spData.getTemplates();
    // получаем мем по id, сырой список превратили в стринг
    return rawTemplates
        .map((rawTemplate) => Template.fromJson(json.decode(rawTemplate)))
        .toList();
  }

  // сохранение списка избранного в локальном хранилище
  // и его отображение на экране
  Future<Template?> getTemplate(final String id) async {
    // получаем template
    final templates = await getTemplates();
    return templates.firstWhereOrNull((template) => template.id == id);
  }

  Future<bool> _setTemplates(final List<Template> templates) async {
    final rawTemplates = templates.map((template) => json.encode(template.toJson())).toList();
    // сохраняем
    return _setRawTemplates(rawTemplates);
  }

  Future<bool> _setRawTemplates(final List<String> rawTemplates) {
    updater.add(null);
    return spData.setTemplates(rawTemplates);
  }
}
