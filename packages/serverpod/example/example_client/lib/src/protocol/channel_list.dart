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

class ChannelList extends SerializableEntity {
  @override
  String get className => 'ChannelList';

  late List<Channel> channels;

  ChannelList({
    required this.channels,
  });

  ChannelList.fromSerialization(Map<String, dynamic> serialization) {
    var _data = unwrapSerializationData(serialization);
    channels = _data['channels']!
        .map<Channel>((a) => Channel.fromSerialization(a))
        ?.toList();
  }

  @override
  Map<String, dynamic> serialize() {
    return wrapSerializationData({
      'channels': channels.map((Channel a) => a.serialize()).toList(),
    });
  }
}
