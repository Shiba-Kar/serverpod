/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: unused_import
// ignore_for_file: unnecessary_import
// ignore_for_file: overridden_fields
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: depend_on_referenced_packages

import 'package:serverpod_client/serverpod_client.dart';
import 'dart:typed_data';
import 'protocol.dart';

class AppleAuthInfo extends SerializableEntity {
  @override
  String get className => 'serverpod_auth_server.AppleAuthInfo';

  late String userIdentifier;
  String? email;
  late String fullName;
  late String nickname;
  late String identityToken;
  late String authorizationCode;

  AppleAuthInfo({
    required this.userIdentifier,
    this.email,
    required this.fullName,
    required this.nickname,
    required this.identityToken,
    required this.authorizationCode,
  });

  AppleAuthInfo.fromSerialization(Map<String, dynamic> serialization) {
    var _data = unwrapSerializationData(serialization);
    userIdentifier = _data['userIdentifier']!;
    email = _data['email'];
    fullName = _data['fullName']!;
    nickname = _data['nickname']!;
    identityToken = _data['identityToken']!;
    authorizationCode = _data['authorizationCode']!;
  }

  @override
  Map<String, dynamic> serialize() {
    return wrapSerializationData({
      'userIdentifier': userIdentifier,
      'email': email,
      'fullName': fullName,
      'nickname': nickname,
      'identityToken': identityToken,
      'authorizationCode': authorizationCode,
    });
  }
}
