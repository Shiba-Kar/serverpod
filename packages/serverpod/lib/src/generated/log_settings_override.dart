/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: unused_import
// ignore_for_file: unnecessary_import
// ignore_for_file: overridden_fields
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: depend_on_referenced_packages

import 'package:serverpod_serialization/serverpod_serialization.dart';
import 'dart:typed_data';
import 'protocol.dart';

class LogSettingsOverride extends SerializableEntity {
  @override
  String get className => 'LogSettingsOverride';

  String? module;
  String? endpoint;
  String? method;
  late LogSettings logSettings;

  LogSettingsOverride({
    this.module,
    this.endpoint,
    this.method,
    required this.logSettings,
  });

  LogSettingsOverride.fromSerialization(Map<String, dynamic> serialization) {
    var _data = unwrapSerializationData(serialization);
    module = _data['module'];
    endpoint = _data['endpoint'];
    method = _data['method'];
    logSettings = LogSettings.fromSerialization(_data['logSettings']);
  }

  @override
  Map<String, dynamic> serialize() {
    return wrapSerializationData({
      'module': module,
      'endpoint': endpoint,
      'method': method,
      'logSettings': logSettings.serialize(),
    });
  }

  @override
  Map<String, dynamic> serializeAll() {
    return wrapSerializationData({
      'module': module,
      'endpoint': endpoint,
      'method': method,
      'logSettings': logSettings.serialize(),
    });
  }
}
