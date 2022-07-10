import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/data/repositories/templates_repository.dart';
import 'package:memogenerator/domain/interactors/save_template_interactor.dart';
import 'package:memogenerator/presentation/main/memes_with_docs_path.dart';
import 'package:memogenerator/presentation/main/models/template_full.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class MainBloc {
  Stream<MemesWithDocsPath> observeMemesWithDocsPath() {
    return Rx.combineLatest2<List<Meme>, Directory, MemesWithDocsPath>(
      MemesRepository.getInstance().observeMemes(), // получает мемы
      getApplicationDocumentsDirectory().asStream(), // получает папку
      (memes, docsDirectory) =>
          MemesWithDocsPath(memes, docsDirectory.path), // в одну модель
    );
  }

  Stream<List<TemplateFull>> observeTemplates() {
    return Rx.combineLatest2<List<Template>, Directory, List<TemplateFull>>(
      TemplatesRepository.getInstance().observeTemplates(), // получает шаблон
      getApplicationDocumentsDirectory().asStream(), // получает папку
      (templates, docsDirectory) {
        return templates.map((template) {
          final fullImagePath =
              "${docsDirectory.absolute.path}${Platform.pathSeparator}${SaveTemplateInteractor.templatesPathName}${Platform.pathSeparator}${template.imageUrl}";
          return TemplateFull(
            id: template.id,
            fullImagePath: fullImagePath,
          );
        }).toList();
      }, // в одну модель
    );
  }

  Future<String?> selectMeme() async {
    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery);
    final imagePath = xfile?.path;
    if (imagePath != null) {
      await SaveTemplateInteractor.getInstance()
          .saveTemplate(imagePath: imagePath);
    }
    return imagePath;
  }

  Future<void> addToTemplates() async {
    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery);
    final imagePath = xfile?.path;
    if (imagePath != null) {
      await SaveTemplateInteractor.getInstance()
          .saveTemplate(imagePath: imagePath);
    }
  }

  // метода удаления мема с главного экрана
  void deleteMeme(final String memeId) {
    MemesRepository.getInstance().removeFromMemes(memeId);
  }

  void deleteTemplate(final String templateId) {
    TemplatesRepository.getInstance().removeFromTemplates(templateId);
  }

  void dispose() {}



}
