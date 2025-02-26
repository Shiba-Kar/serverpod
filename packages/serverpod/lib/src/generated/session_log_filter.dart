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

class SessionLogFilter extends SerializableEntity {
  @override
  String get className => 'SessionLogFilter';

  String? endpoint;
  String? method;
  String? futureCall;
  late bool slow;
  late bool error;
  late bool open;
  int? lastSessionLogId;

  SessionLogFilter({
    this.endpoint,
    this.method,
    this.futureCall,
    required this.slow,
    required this.error,
    required this.open,
    this.lastSessionLogId,
  });

  SessionLogFilter.fromSerialization(Map<String, dynamic> serialization) {
    var _data = unwrapSerializationData(serialization);
    endpoint = _data['endpoint'];
    method = _data['method'];
    futureCall = _data['futureCall'];
    slow = _data['slow']!;
    error = _data['error']!;
    open = _data['open']!;
    lastSessionLogId = _data['lastSessionLogId'];
  }

  @override
  Map<String, dynamic> serialize() {
    return wrapSerializationData({
      'endpoint': endpoint,
      'method': method,
      'futureCall': futureCall,
      'slow': slow,
      'error': error,
      'open': open,
      'lastSessionLogId': lastSessionLogId,
    });
  }

  @override
  Map<String, dynamic> serializeAll() {
    return wrapSerializationData({
      'endpoint': endpoint,
      'method': method,
      'futureCall': futureCall,
      'slow': slow,
      'error': error,
      'open': open,
      'lastSessionLogId': lastSessionLogId,
    });
  }
}
