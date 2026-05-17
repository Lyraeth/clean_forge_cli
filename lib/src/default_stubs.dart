const defaultStubs = <String, String>{
  'entity': r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part '{{file_name}}.freezed.dart';

@freezed
abstract class {{ClassName}} with _${{ClassName}} {
  const factory {{ClassName}}({
{{fields}}
  }) = _{{ClassName}};
}
''',
  'model': r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part '{{file_name}}.freezed.dart';
part '{{file_name}}.g.dart';

@freezed
abstract class {{ClassName}}Model with _${{ClassName}}Model {
  const factory {{ClassName}}Model({
{{fields}}
  }) = _{{ClassName}}Model;

  factory {{ClassName}}Model.fromJson(Map<String, dynamic> json) =>
      _${{ClassName}}ModelFromJson(json);
}
''',
  'usecase': '''
class {{ClassName}}UseCase {
  const {{ClassName}}UseCase();
}
''',
};
