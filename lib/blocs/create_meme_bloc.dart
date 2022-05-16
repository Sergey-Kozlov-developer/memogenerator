import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class CreateMemeBloc {
  // данные логического объекта, которые получаем в UI
  // отображение текста в верхней части приложения
  final memeTextSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);

  // выделенный в данный момент memeText
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);

  // при нажатии добавить текст, будет создаваться текст на холсте
  void addNewText() {
    final newMemeText = MemeText.create();
    memeTextSubject.add([...memeTextSubject.value, newMemeText]);
    selectedMemeTextSubject.add(newMemeText);
  }

// получить список с текущими memeText и найти нужный и заменить его id
  void changeMemeText(final String id, final String text) {
    final copiedList = [...memeTextSubject.value];
    final index = copiedList.indexWhere((memeText) => memeText.id == id);
    if (index == -1) {
      return;
    }
    copiedList.removeAt(index);
    copiedList.insert(index, MemeText(id: id, text: text));
    memeTextSubject.add(copiedList);
  }

// при нажатии на текст в поле, метод выделяет текст в поле ввода и дает редактировать его
  void selectMemeText(final String id) {
    final foundMemeText =
        memeTextSubject.value.firstWhereOrNull((memeText) => memeText.id == id);
    selectedMemeTextSubject.add(foundMemeText);
  }

  void deselectMemeText() {
    selectedMemeTextSubject.add(null);
  }

  // выдает инфу содерж в этом subject
  Stream<List<MemeText>> observeMemeTexts() => memeTextSubject
      .distinct((prev, next) => ListEquality().equals(prev, next));

  Stream<MemeText?> observeSelectedMemeText() =>
      selectedMemeTextSubject.distinct();

  // Stream возвращающий MemeTextWithSelection
  Stream<List<MemeTextsWithSelection>> observeMemeTextsWithSelection() {
    return Rx.combineLatest2<List<MemeText>, MemeText?,
        List<MemeTextsWithSelection>>(
      observeMemeTexts(),
      observeSelectedMemeText(),
      (memeTexts, selectedMemeText) {
        return memeTexts.map((memeText) {
          return MemeTextsWithSelection(
            memetext: memeText,
            selected: memeText.id == selectedMemeText?.id,
          );
        }).toList();
      },
    );
  }

  void dispose() {
    memeTextSubject.close();
    selectedMemeTextSubject.close();
  }
}

// информация нетолько о выделенном тексте но и выделен ли он
class MemeTextsWithSelection {
  final MemeText memetext;
  final bool selected;

  MemeTextsWithSelection({
    required this.memetext,
    required this.selected,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemeTextsWithSelection &&
          runtimeType == other.runtimeType &&
          memetext == other.memetext &&
          selected == other.selected;

  @override
  int get hashCode => memetext.hashCode ^ selected.hashCode;

  @override
  String toString() {
    return 'MemeTextWithSelection{memetext: $memetext, selected: $selected}';
  }
}

// создание уникального индефикатора содержащего текст нашей надписи
class MemeText {
  final String id;
  final String text;

  MemeText({required this.id, required this.text});

  factory MemeText.create() {
    return MemeText(id: Uuid().v4(), text: "");
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemeText &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text;

  @override
  int get hashCode => id.hashCode ^ text.hashCode;

  @override
  String toString() {
    return 'MemeText{id: $id, text: $text}';
  }
}
