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
    final newImagePath = await createNewFile(imagePath);

    final meme = Meme(
      id: id,
      texts: textWithPositions,
      memePath: newImagePath,
    );
    return await MemesRepository.getInstance().addToMemes(meme);
  }

  // возвращение корректного пути файла
  Future<String> createNewFile(final String imagePath) async {
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
      return newImagePath;
    }
    // запрашиваем размер файла
    final oldFileLength = await (oldFileWithTheSameName as File).length();
    // сколько занимает места файл, который хотим скопировать
    final newFileLength = await tempFile.length();
    if (oldFileLength == newFileLength) {
      return newImagePath;
    }
    //последняя точка до расширения файла
    return _createFileForSameNameButDifferentLength(
      imageName: imageName,
      tempFile: tempFile,
      newImagePath: newImagePath,
      memePath: memePath,
    );
  }

  Future<String> _createFileForSameNameButDifferentLength({
      required final String imageName,
      required final File tempFile,
      required final String newImagePath,
      required final String memePath}) async {
    final indexOfLastDot = imageName.lastIndexOf(".");
    // избавляемся от расширения файла
    if (indexOfLastDot == -1) {
      // скопировали в новую папку
      await tempFile.copy(newImagePath);
      return newImagePath;
    }
    final extension = imageName.substring(indexOfLastDot);
    final imageNameWithoutExtension = imageName.substring(0, indexOfLastDot);
    final indexOfLastUnderscore = imageNameWithoutExtension.lastIndexOf("_");
    if (indexOfLastUnderscore == -1) {
      final correctedNewImagePath =
          "$memePath${Platform.pathSeparator}${imageNameWithoutExtension}_1$extension";
      // скопировали в новую папку
      await tempFile.copy(correctedNewImagePath);
      return correctedNewImagePath;
    }
    final suffixNumberString =
        imageNameWithoutExtension.substring(indexOfLastUnderscore + 1);
    final suffixNumber = int.tryParse(suffixNumberString);
    if (suffixNumber == null) {
      final correctedNewImagePath =
          "$memePath${Platform.pathSeparator}${imageNameWithoutExtension}_1$extension";
      await tempFile.copy(correctedNewImagePath);
      return correctedNewImagePath;
    } else {
      final imageNameWithoutSuffix =
          imageNameWithoutExtension.substring(0, indexOfLastUnderscore);
      final correctedNewImagePath =
          "$memePath${Platform.pathSeparator}${imageNameWithoutSuffix}_${suffixNumber + 1}$extension";
      await tempFile.copy(correctedNewImagePath);
      return correctedNewImagePath;
    }
  }

  String _getFileNameByPath(String imagePath) =>
      imagePath.split(Platform.pathSeparator).last;
}
