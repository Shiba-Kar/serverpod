import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:pedantic/pedantic.dart';
import 'package:serverpod/server.dart';
import 'package:serverpod_serialization/serverpod_serialization.dart';

import 'endpoint_dispatch.dart';
import 'future_call.dart';
import 'future_call_manager.dart';
import 'serverpod.dart';
import '../authentication/authentication_info.dart';
import '../cache/caches.dart';
import '../database/database_config.dart';
import 'package:serverpod/src/server/health_check.dart';

/// Handling incoming calls and routing them to the correct [Endpoint]
/// methods.
class Server {
  /// The [Serverpod] managing the server.
  final Serverpod serverpod;

  /// The id of the server. If running in a cluster, all servers need unique
  /// ids.
  final int serverId;

  /// Port the server is listening on.
  final int port;

  /// The [ServerpodRunMode] the server is running in.
  final String runMode;

  /// Current database configuration.
  DatabaseConfig databaseConfig;

  /// The [SerializationManager] used by the server.
  final SerializationManager serializationManager;

  /// [AuthenticationHandler] responsible for authenticating users.
  final AuthenticationHandler? authenticationHandler;

  /// Caches used by the server.
  final Caches caches;

  /// The name of the server.
  final String name;

  /// Security context if the server is running over https.
  final SecurityContext? securityContext;

  /// Responsible for dispatching calls to the correct [Endpoint] methods.
  final EndpointDispatch endpoints;

  bool _running = false;
  /// True if the server is currently running.
  bool get running => _running;

  late final HttpServer _httpServer;
  /// The [HttpServer] responsible for handling calls.
  HttpServer get httpServer => _httpServer;

  late final FutureCallManager _futureCallManager;

  /// Currently not in use.
  List<String>? whitelistedExternalCalls;

  /// Map of passwords loaded from config/passwords.yaml
  Map<String, String> passwords;

  /// Creates a new [Server] object.
  Server({
    required this.serverpod,
    required this.serverId,
    required this.port,
    required this.serializationManager,
    required this.databaseConfig,
    required this.passwords,
    required this.runMode,
    this.authenticationHandler,
    String? name,
    required this.caches,
    this.securityContext,
    this.whitelistedExternalCalls,
    required this.endpoints,
  }) :
    name = name ?? 'Server id $serverId'
  {
    // Setup future calls
    _futureCallManager = FutureCallManager(this, serializationManager);
  }

  /// Registers a future call by its name.
  void registerFutureCall(FutureCall call, String name) {
    _futureCallManager.registerFutureCall(call, name);
  }

  /// Calls a [FutureCall] by its name after the specified delay, optionally
  /// passing a [SerializableEntity] object as parameter.
  void futureCallWithDelay(String callName, SerializableEntity? object, Duration delay) {
    assert(_running, 'Server is not running, call start() before using future calls');
    _futureCallManager.scheduleFutureCall(callName, object, DateTime.now().add(delay), serverId);
  }

  /// Calls a [FutureCall] by its name at the specified time, optionally passing
  /// a [SerializableEntity] object as parameter.
  void futureCallAtTime(String callName, SerializableEntity? object, DateTime time) {
    assert(_running, 'Server is not running, call start() before using future calls');
    _futureCallManager.scheduleFutureCall(callName, object, time, serverId);
  }

  /// Starts the server.
  Future<void> start() async {
    if (securityContext != null) {
      await HttpServer.bindSecure(InternetAddress.anyIPv6, port, securityContext!).then(
      _runServer,
      onError: (e, StackTrace stackTrace) {
        stderr.writeln('${DateTime.now().toUtc()} Internal server error. Failed to bind secure socket.');
        stderr.writeln('$e');
        stderr.writeln('$stackTrace');
      });
    }
    else {
      await HttpServer.bind(InternetAddress.anyIPv6, port).then(
      _runServer,
      onError: (e, StackTrace stackTrace) {
        stderr.writeln('${DateTime.now().toUtc()} Internal server error. Failed to bind socket.');
        stderr.writeln('$e');
        stderr.writeln('$stackTrace');
      });
    }

    // Start future calls
    _futureCallManager.start();

    _running = true;
    print('$name listening on port $port');
  }

  void _runServer(HttpServer httpServer) {
    _httpServer = httpServer;
    httpServer.autoCompress = true;
    httpServer.listen(
          (HttpRequest request) {
        try {
          _handleRequest(request);
        }
        catch(e, stackTrace) {
          stderr.writeln('${DateTime.now().toUtc()} Internal server error. _handleRequest failed.');
          stderr.writeln('$e');
          stderr.writeln('$stackTrace');
        }
      },
      onError: (e, StackTrace stackTrace) {
        stderr.writeln('${DateTime.now().toUtc()} Internal server error. httpSever.listen failed.');
        stderr.writeln('$e');
        stderr.writeln('$stackTrace');
      },
    ).onDone(() {
      print('$name stopped');
    });
  }

  Future<void> _handleRequest(HttpRequest request) async {
    Uri uri;

    try {
      uri = request.requestedUri;
    }
    catch(e) {
      if (serverpod.runtimeSettings.logMalformedCalls) {
        // TODO: Specific log for this?
        unawaited(serverpod.log('Malformed call, invalid uri from ${request.connectionInfo!.remoteAddress.address}'));
        print('Malformed call, invalid uri from ${request.connectionInfo!.remoteAddress.address}');
      }

      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    if (uri.path == '/') {
      // Perform health checks
      var checks = await performHealthChecks(serverpod);
      var issues = <String>[];
      var allOk = true;
      for (var metric in checks.metrics) {
        if (!metric.isHealthy) {
          allOk = false;
          issues.add('${metric.name}: ${metric.value}');
        }
      }

      if (allOk)
        request.response.writeln('OK ${DateTime.now().toUtc()}');
      else
        request.response.writeln('SADNESS ${DateTime.now().toUtc()}');
      for (var issue in issues)
        request.response.writeln(issue);

      await request.response.close();
      return;
    }
    else if (uri.path == '/websocket') {
      var webSocket =  await WebSocketTransformer.upgrade(request);
      unawaited(_handleWebsocket(webSocket, request));
      return;
    }

    // TODO: Limit check external calls
//    bool checkLength = true;
//    if (whitelistedExternalCalls != null && whitelistedExternalCalls.contains(uri.path))
//      checkLength = false;
//
//    if (checkLength) {
//      // Check size of the request
//      int contentLength = request.contentLength;
//      if (contentLength == -1 ||
//          contentLength > serverpod.config.maxRequestSize) {
//        if (serverpod.runtimeSettings.logMalformedCalls)
//          logDebug('Malformed call, invalid content length ($contentLength): $uri');
//        request.response.statusCode = HttpStatus.badRequest;
//        request.response.close();
//        return;
//      }
//    }

    String? body;
    try {
      body = await _readBody(request);
    }
    catch (e, stackTrace) {
      stderr.writeln('${DateTime.now().toUtc()} Internal server error. Failed to read body of request.');
      stderr.writeln('$e');
      stderr.writeln('$stackTrace');
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    var result = await _handleUriCall(uri, body!, request);

    if (result is ResultInvalidParams) {
      if (serverpod.runtimeSettings.logMalformedCalls) {
        unawaited(serverpod.log('Malformed call: $result'));
        print('Malformed call: $result');
      }
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }
    else if (result is ResultAuthenticationFailed) {
      if (serverpod.runtimeSettings.logMalformedCalls) {
        unawaited(serverpod.log('Access denied: $result'));
        print('Access denied: $result');
      }
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }
    else if (result is ResultInternalServerError) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.writeln('Internal server error. Call log id: ${result.sessionLogId}');
      await request.response.close();
      return;
    }
    else if (result is ResultStatusCode) {
      request.response.statusCode = result.statusCode;
      await request.response.close();
      return;
    }
    else if (result is ResultSuccess) {
      // Set content type.
      if (!result.sendByteDataAsRaw)
        request.response.headers.contentType = ContentType('application', 'json', charset: 'utf-8');

      // Set Access-Control-Allow-Origin, required for Flutter web.
      request.response.headers.add('Access-Control-Allow-Origin', '*');

      // Send the response
      if (result.sendByteDataAsRaw && result.returnValue is ByteData?) {
        var byteData = result.returnValue as ByteData?;
        if (byteData != null)
          request.response.add(byteData.buffer.asUint8List());
      }
      else {
        var serializedEntity = serializationManager.serializeEntity(result.returnValue);
        request.response.write(serializedEntity);
      }
      await request.response.close();
      return;
    }
  }

  Future<String?> _readBody(HttpRequest request) async {
    // TODO: Find more efficient solution?
    var len = 0;
    var data = <int>[];
    await for (var segment in request) {
      len += segment.length;
      if (len > serverpod.config.maxRequestSize)
        return null;
      data += segment;
    }
    return Utf8Decoder().convert(data);
  }

  Future<Result> _handleUriCall(Uri uri, String body, HttpRequest request) async {
    var endpointName = uri.path.substring(1);
    return endpoints.handleUriCall(this, endpointName, uri, body, request);
  }

  Future<void> _handleWebsocket(WebSocket webSocket, HttpRequest request) async {
    try {
      var session = Session(
        server: this,
        type: SessionType.stream,
        uri: request.uri,
        httpRequest: request,
        webSocket: webSocket,
      );

      try {
        try {
          // Notify all streaming endpoints that the stream has started.
          for (var endpointConnector in endpoints.connectors.values) {
            await endpointConnector.endpoint.setupStream(session);
          }
        }
        catch(e) {
          print('Failed to setup stream');
          // TODO: Logging
        }

        await for (String jsonData in webSocket) {

          var data = jsonDecode(jsonData) as Map;
          var endpointName = data['endpoint'] as String;
          var serialization = data['object'] as Map;
          var message = serializationManager.createEntityFromSerialization(serialization.cast<String,dynamic>());

          if (message == null)
            throw Exception('Streamed message was null');

          var endpointConnector = endpoints.getConnectorByName(endpointName);
          if (endpointConnector == null)
            throw Exception('Endpoint not found: $endpointName');

          await endpointConnector.endpoint.handleStreamMessage(session, message);
        }
      }
      catch(e) {
        print('WS exception: $e');
      }
    }
    catch(e) {
      return;
    }
  }

  /// Shuts the server down.
  void shutdown() {
    _httpServer.close();
    _futureCallManager.stop();
    _running = false;
  }
}