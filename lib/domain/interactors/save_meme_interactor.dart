import 'dart:io';

import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:path_provider/path_provider.dart';

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
    await Directory(memePath).create(recursive: true);
    // imageName получение названия файлика
    final imageName = imagePath.split(Platform.pathSeparator).last;
    // fullImagePath новый путь
    final newImagePath = "$memePath${Platform.pathSeparator}$imageName";
    final tempFile = File(imagePath);
    // скопировали в новую папку
    await tempFile.copy(newImagePath);

    final meme = Meme(
      id: id,
      texts: textWithPositions,
      memePath: newImagePath,
    );
    return await MemesRepository.getInstance().addToMemes(meme);
  }
}
