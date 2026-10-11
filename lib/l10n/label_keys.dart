import '../models/investigation.dart';

/// Maps stored enum values to translation keys. The enums themselves stay
/// language-neutral so saved investigations remain readable in any language.
String classificationKey(AudioClassification c) => 'cls_${c.name}';

String responseStatusKey(ResponseStatus s) => 'st_${s.name}';

String repeatComparisonKey(RepeatComparison r) => 'rc_${r.name}';
