import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/presentation/main/memes_with_docs_path.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: WillPopScope(
        onWillPop: () async {
          final goBack = await showConfirmationExitDualog(context);
          // нажали вне нашего диалога
          return goBack ?? false;
        },
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text(
                "Мемогенератор",
                style: GoogleFonts.seymourOne(fontSize: 24),
              ),
              bottom: TabBar(
                labelColor: AppColors.darkGrey,
                indicatorColor: AppColors.fuchsia,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    text: "Созданные".toUpperCase(),
                  ),
                  Tab(
                    text: "Шаблоны".toUpperCase(),
                  ),
                ],
              ),
              backgroundColor: AppColors.lemon,
              foregroundColor: AppColors.darkGrey,
            ),
            floatingActionButton: CreateMemeFab(),
            backgroundColor: Colors.white,
            body: TabBarView(
              children: [
                SafeArea(child: TemplatesGrid()),
                SafeArea(child: TemplatesGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> showConfirmationExitDualog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Точно хотите выйти?"),
          actionsPadding: EdgeInsets.symmetric(horizontal: 16),
          content: Text("Мемы сами себя не сделают"),
          actions: [
            AppButton(
              onTap: () {
                Navigator.of(context).pop(false);
              },
              text: "Остаться",
              color: AppColors.darkGrey,
            ),
            AppButton(
              onTap: () {
                Navigator.of(context).pop(true);
              },
              text: "Выйти",
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class CreateMemeFab extends StatelessWidget {
  const CreateMemeFab({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return FloatingActionButton.extended(
      onPressed: () async {
        final selectedMemePath = await bloc.selectMeme();
        if (selectedMemePath == null) {
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateMemePage(
              selectedMemePath: selectedMemePath,
            ),
          ),
        );
      },
      backgroundColor: AppColors.fuchsia,
      icon: Icon(Icons.add, color: Colors.white),
      label: Text("Создать"),
    );
  }
}

class CreatedMemesGrid extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<MemesWithDocsPath>(
      stream: bloc.observeMemesWithDocsPath(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final items = snapshot.requireData.memes;
        final docsPath = snapshot.requireData.docsPath;
        return GridView.extent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          children: items.map((item) {
            return GridItem(meme: item, docsPath: docsPath);
          }).toList(),
        );
      },
    );
  }
}

class GridItem extends StatelessWidget {
  const GridItem({
    Key? key,
    required this.meme,
    required this.docsPath,
  }) : super(key: key);

  final Meme meme;
  final String docsPath;

  @override
  Widget build(BuildContext context) {
    final imageFile = File("$docsPath${Platform.pathSeparator}${meme.id}.png");
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return CreateMemePage(id: meme.id);
            },
          ),
        );
      },
      child: Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.darkGrey, width: 1),
        ),
        child: imageFile.existsSync()
            ? Image.file(
                File("$docsPath${Platform.pathSeparator}${meme.id}.png"),
              )
            : Text(meme.id),
      ),
    );
  }
}
class TemplatesGrid extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<MemesWithDocsPath>(
      stream: bloc.observeMemesWithDocsPath(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final items = snapshot.requireData.memes;
        final docsPath = snapshot.requireData.docsPath;
        return GridView.extent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          children: items.map((item) {
            return GridItem(meme: item, docsPath: docsPath);
          }).toList(),
        );
      },
    );
  }
}