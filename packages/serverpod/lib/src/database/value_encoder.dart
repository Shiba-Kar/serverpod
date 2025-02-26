import 'dart:convert';
import 'dart:typed_data';

// ignore: implementation_imports
import 'package:postgres/src/text_codec.dart';

/// Overrides the [PostgresTextEncoder] to add support for [ByteData].
class ValueEncoder extends PostgresTextEncoder {
  @override
  String convert(value, {bool escapeStrings = true}) {
    if (value is ByteData) {
      var encoded = base64Encode(value.buffer.asUint8List());
      return 'decode(\'$encoded\', \'base64\')';
    } else if (value is String &&
        value.startsWith('decode(\'') &&
        value.endsWith('\', \'base64\')')) {
      // TODO:
      // This is a bit of a hack to get ByteData working. Strings that starts
      // with `convert('` and ends with `', 'base64') will be incorrectly
      // encoded to base64. Best would be to find a better way to detect when we
      // are trying to store a ByteData.
      return value;
    }
    return super.convert(value, escapeStrings: escapeStrings);
  }
}
