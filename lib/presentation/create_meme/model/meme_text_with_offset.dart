// информация нетолько о выделенном тексте но и выделен ли он
import 'dart:ui';

import 'package:equatable/equatable.dart';

class MemeTextsWithOffset extends Equatable {
  final String id;
  final String text;
  final Offset? offset;


  MemeTextsWithOffset({
    required this.id,
    required this.text,
    required this.offset,
  });

  @override
  List<Object?> get props => [id, text, offset];


}