// создание уникального индефикатора содержащего текст нашей надписи
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class MemeText extends Equatable {
  final String id;
  final String text;

  MemeText({required this.id, required this.text});

  factory MemeText.create() {
    return MemeText(id: Uuid().v4(), text: "");
  }

  @override
  // TODO: implement props
  List<Object?> get props => [id, text];


}