import 'dart:convert';
import 'dart:io';

import 'package:fake_http_client/fake_http_client.dart';
import 'package:test/test.dart';

class HttpTestOverrides extends HttpOverrides {
  FakeHttpClient fakeHttpClient;

  @override
  HttpClient createHttpClient(SecurityContext context) => fakeHttpClient;
}

void main() {
  final HttpTestOverrides overrides = HttpTestOverrides();
  HttpOverrides.global = overrides;

  group(FakeHttpClient, () {
    setUp(() {
      overrides.fakeHttpClient =
          FakeHttpClient((HttpClientRequest request, FakeHttpClient client) {
        return FakeHttpResponse(
          body: 'Hello World',
          statusCode: HttpStatus.ok,
          headers: {'foo': 'bar'},
        );
      });
    });

    tearDown(() {
      overrides.fakeHttpClient = null;
    });

    test('can be provided using HttpOverrides', () {
      final HttpClient client = HttpClient();

      expect(client, isA<FakeHttpClient>());
    });

    test('returns a body of "Hello World" and headers', () async {
      final client = HttpClient();
      final request = await client.getUrl(Uri.https('google.com', '/'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(body, 'Hello World');
      expect(response.headers.value('foo'), 'bar');
    });

    group(FakeHttpHeaders, () {
      HttpHeaders headers;

      setUp(() async {
        final client = HttpClient();
        final request = await client.getUrl(Uri.https('google.com', '/'));
        headers = request.headers;
      });

      tearDown(() {
        headers = null;
      });

      test('return the value if headers.value has one entry', () {
        headers.add('foo', 'bar');

        expect(headers.value('foo'), 'bar');
      });

      test('returns null if headers.value has no entries', () {
        expect(headers.value('bar'), null);
      });

      test('throws if headers.value has more than one entry', () {
        headers..add('foo', 'bar')..add('foo', 'class');

        expect(() => headers.value('foo'), throwsA(isA<StateError>()));
      });
    });
  });
}
