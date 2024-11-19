import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_http_client/fake_http_client.dart';

class _FakeDataHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(_) => FakeHttpClient(
        (request, client) {
          final url = request.uri.toString();

          if (url.contains('non-existing-site')) {
            return FakeHttpResponse(
              body: 'Hey!',
            );
          } else {
            return FakeHttpResponse(
              statusCode: HttpStatus.unauthorized,
              body: 'Sorry, please sign in!',
            );
          }
        },
      );
}

void main() {
  HttpOverrides.runWithHttpOverrides(
    () async {
      final client = HttpClient();

      final demoUrls = ['https://non-existing-site.com', 'https://foo.com'];

      for (final demoUrl in demoUrls) {
        final request = await client.getUrl(Uri.parse(demoUrl));
        final response = await request.close();
        final responseStatus = response.statusCode;
        final responseBody = await _readResponseBody(response);

        stdout.writeln(
          "'$demoUrl' - $responseStatus - $responseBody",
        );
      }
    },
    _FakeDataHttpOverrides(),
  );
}

Future<String> _readResponseBody(HttpClientResponse response) {
  final completer = Completer<String>();
  final contents = StringBuffer();

  response.transform(utf8.decoder).listen(
        contents.write,
        onDone: () => completer.complete(contents.toString()),
      );

  return completer.future;
}
