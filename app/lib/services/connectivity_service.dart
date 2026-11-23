import 'dart:async';
import 'dart:io';

/// Tells whether the phone can reach the internet (SD1 / SD5: isOnline()).
class ConnectivityService {
  const ConnectivityService({this.host = 'one.one.one.one'});

  final String host;

  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}
