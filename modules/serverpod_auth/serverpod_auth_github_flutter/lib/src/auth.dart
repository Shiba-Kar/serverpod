import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:github_sign_in/github_sign_in.dart';
import 'package:serverpod_auth_client/module.dart';
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';

/// Attempts to Sign in with GitHub. If successful, a [UserInfo] is returned.
/// If the attempt is not a success, null is returned.
Future<UserInfo?> signInWithGitHub(
  Caller caller, {
  required BuildContext context,
  required String clientId,
  required String clientSecret,
  required String redirectUrl,
}) async {
  try {
    // Attempt to sign in.

    final GitHubSignIn gitHubSignIn = GitHubSignIn(
      clientId: clientId,
      clientSecret: clientSecret,
      redirectUrl: redirectUrl,
    );
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('$e');
      print('$stackTrace');
    }
    return null;
  }
}
/* final GitHubSignIn gitHubSignIn = GitHubSignIn(
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUrl: redirectUrl);
    var result = await gitHubSignIn.signIn(context);
    switch (result.status) {
      case GitHubSignInResultStatus.ok:
        print(result.token)
        break;

      case GitHubSignInResultStatus.cancelled:
      case GitHubSignInResultStatus.failed:
        print(result.errorMessage);
        break;
    } */