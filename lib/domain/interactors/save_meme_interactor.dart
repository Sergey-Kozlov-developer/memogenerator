import 'dart:io';

import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';

class SaveMemeInteractor {
  static SaveMemeInteractor? _instance;

  factory SaveMemeInteractor.getInstance() =>
      _instance ??= SaveMemeInteractor._internal();

  SaveMemeInteractor._internal();

  Future<bool> saveMeme({
    required final String id,
    required final List<TextWithPosition> textWithPositions,
    final String? imagePath,
  }) async {
    // imagePath сохранение картинки
    if (imagePath == null) {
      final meme = Meme(id: id, texts: textWithPositions);
      return await MemesRepository.getInstance().addToMemes(meme);
    }
    // docsPath получение доступа где хранятся картинки
    final docsPath = await getApplicationDocumentsDirectory();
    // папка с мемами создаем ее
    final memePath = "${docsPath.absolute.path}${Platform.pathSeparator}memes";
    final memesDirectory = Directory(memePath);
    await memesDirectory.create(recursive: true);

    // получение текущего списка с файлами
    final currentFiles = memesDirectory.listSync();

    // imageName получение названия файлика
    final imageName = _getFileNameByPath(imagePath);
    // есть ли файл сейчас с таким же названием
    final oldFileWithTheSameName = currentFiles.firstWhereOrNull(
      (element) {
        return _getFileNameByPath(element.path) == imageName && element is File;
      },
    );
    // fullImagePath новый путь
    final newImagePath = "$memePath${Platform.pathSeparator}$imageName";
    // создаем новый файл
    final tempFile = File(imagePath);
    if (oldFileWithTheSameName == null) {
      // скопировали в новую папку
      await tempFile.copy(newImagePath);
    } else {
      // запрашиваем размер файла
      final oldFileLength = await (oldFileWithTheSameName as File).length();
      // сколько занимает места файл, который хотим скопировать
      final newFileLength = await tempFile.length();
      if (oldFileLength != newFileLength) {
        // избавляемся от расширения файла

      }
    }

    final meme = Meme(
      id: id,
      texts: textWithPositions,
      memePath: newImagePath,
    );
    return await MemesRepository.getInstance().addToMemes(meme);
  }

  String _getFileNameByPath(String imagePath) =>
      imagePath.split(Platform.pathSeparator).last;
}
