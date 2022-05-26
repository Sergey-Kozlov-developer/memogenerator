import 'dart:async';
import 'dart:ui';

import 'package:memogenerator/data/model/meme.dart';
import 'package:memogenerator/data/model/position.dart';
import 'package:memogenerator/data/model/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/presentation/create_meme/model/meme_text_offset.dart';
import 'package:memogenerator/presentation/create_meme/model/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/model/meme_text_with_selection.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class CreateMemeBloc {
  // данные логического объекта, которые получаем в UI
  // отображение текста в верхней части приложения
  final memeTextSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);

  // выделенный в данный момент memeText
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);

  final memeTextOffsetsSubject =
      BehaviorSubject<List<MemeTextOffset>>.seeded(<MemeTextOffset>[]);

  // создание асихронного метода changeMemeTextOffset
  final newMemeTextOffsetSubject =
      BehaviorSubject<MemeTextOffset?>.seeded(null);

  StreamSubscription<MemeTextOffset?>? newMemeTextOffsetSubscription;
  StreamSubscription<bool>? saveMemeSubscription;

  // конструктор слушатель
  // добавляем debounceTime для сохранения положения после того как мы
  // перестали передвигать текст
  final String id = Uuid().v4();

  CreateMemeBloc() {
    _subscribeToNewMemTextOffset();
  }

  // сохранеие текста позиции в shared_pref
  void saveMeme() {
    final memeTexts = memeTextSubject.value;
    final memTextsOffsets = memeTextOffsetsSubject.value;
    final textsWithPositions = memeTexts.map((memeText) {
      final memeTextPosition =
          memTextsOffsets.firstWhereOrNull((memTextsOffset) {
        return memTextsOffset.id == memeText.id;
      });
      final position = Position(
        top: memeTextPosition?.offset.dy ?? 0,
        left: memeTextPosition?.offset.dx ?? 0,
      );
      return TextWithPosition(
          id: memeText.id, text: memeText.text, position: position);
    }).toList();
    final meme = Meme(id: id, texts: textsWithPositions);
    saveMemeSubscription =
        MemesRepository.getInstance().addToMemes(meme).asStream().listen(
      (saved) {
        print("Meme saved: $saved");
      },
      onError: (error, stackTrace) =>
          print("Error in newMemeTextOffsetSubscription: $error, $stackTrace"),
    );
  }

  void _subscribeToNewMemTextOffset() {
    newMemeTextOffsetSubscription = newMemeTextOffsetSubject
        .debounceTime(Duration(milliseconds: 300))
        .listen(
      (newMemeTextOffset) {
        if (newMemeTextOffset != null) {
          _changeMemeTextOffsetInternal(newMemeTextOffset);
        }
      },
      onError: (error, stackTrace) =>
          print("Error in newMemeTextOffsetSubscription: $error, $stackTrace"),
    );
  }

  void changeMemeTextOffset(final String id, final Offset offset) {
    newMemeTextOffsetSubject.add(MemeTextOffset(id: id, offset: offset));
  }

  // добавляем мем и сетим его в offset
  void _changeMemeTextOffsetInternal(final MemeTextOffset newMemeTextOffset) {
    final copiedMemeTextOffset = [...memeTextOffsetsSubject.value];
    final currentMemeTextOffset = copiedMemeTextOffset.firstWhereOrNull(
        (memeTextOffset) => memeTextOffset.id == newMemeTextOffset.id);
    if (currentMemeTextOffset != null) {
      copiedMemeTextOffset.remove(currentMemeTextOffset);
    }
    // добовляем новый элемент
    copiedMemeTextOffset.add(newMemeTextOffset);
    memeTextOffsetsSubject.add(copiedMemeTextOffset);
  }

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
            memeText: memeText,
            selected: memeText.id == selectedMemeText?.id,
          );
        }).toList();
      },
    );
  }

  void dispose() {
    memeTextSubject.close();
    selectedMemeTextSubject.close();
    memeTextOffsetsSubject.close();
    newMemeTextOffsetSubject.close();
    newMemeTextOffsetSubscription?.cancel();
    saveMemeSubscription?.cancel();
  }
}
