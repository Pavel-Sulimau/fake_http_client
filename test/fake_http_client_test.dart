import 'dart:convert';
import 'dart:io';

import 'package:fake_http_client/fake_http_client.dart';
import 'package:http/io_client.dart';
import 'package:test/test.dart';

class _HttpTestOverrides extends HttpOverrides {
  FakeHttpClient? fakeHttpClient;
  @override
  HttpClient createHttpClient(SecurityContext? context) => fakeHttpClient!;
}

void main() {
  final _HttpTestOverrides _httpOverrides = _HttpTestOverrides();
  HttpOverrides.global = _httpOverrides;

  group(FakeHttpClient, () {
    setUp(() {
      _httpOverrides.fakeHttpClient =
          FakeHttpClient((HttpClientRequest request, FakeHttpClient client) {
        return FakeHttpResponse(
          body: 'Hello World',
          statusCode: HttpStatus.ok,
          headers: {'foo': 'bar'},
        );
      });
    });

    tearDown(() {
      _httpOverrides.fakeHttpClient = null;
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

    test('post request body can be obtained in request callback', () async {
      const expectedPostRequestBody = 'Convey my regards!';
      String? actualPostRequestBody;

      final fakeHttpClient = FakeHttpClient(
          (FakeHttpClientRequest request, FakeHttpClient client) {
        actualPostRequestBody = request.bodyText;
        return FakeHttpResponse(
          body: 'Hey',
          statusCode: HttpStatus.ok,
        );
      });

      final ioClient = IOClient(fakeHttpClient);
      final response = await ioClient.post(
        Uri.parse('https://smth.com/comments'),
        body: expectedPostRequestBody,
      );

      expect(actualPostRequestBody, expectedPostRequestBody);
      expect(response.statusCode, HttpStatus.ok);
    });

    test('get request body is empty in request callback', () async {
      String? actualPostRequestBody;

      final fakeHttpClient = FakeHttpClient((
        FakeHttpClientRequest request,
        FakeHttpClient client,
      ) {
        actualPostRequestBody = request.bodyText;
        return FakeHttpResponse(
          body: 'Hey',
          statusCode: HttpStatus.ok,
        );
      });

      final ioClient = IOClient(fakeHttpClient);
      final response =
          await ioClient.get(Uri.parse('https://smth.com/comments/1'));

      expect(actualPostRequestBody, '');
      expect(response.statusCode, HttpStatus.ok);
    });

    group(FakeHttpHeaders, () {
      late HttpHeaders headers;

      setUp(() async {
        final client = HttpClient();
        final request = await client.getUrl(Uri.https('google.com', '/'));
        headers = request.headers;
      });

      test('return the value if headers.value has one entry', () {
        headers.add('foo', 'bar');

        expect(headers.value('foo'), 'bar');
      });

      test('returns null if headers.value has no entries', () {
        expect(headers.value('bar'), null);
      });

      test('throws if headers.value has more than one entry', () {
        headers
          ..add('foo', 'bar')
          ..add('foo', 'class');

        expect(() => headers.value('foo'), throwsA(isA<StateError>()));
      });
    });
  });

  group('HttpClient', () {
    setUp(() {
      // Overrides all HttpClients.
      HttpOverrides.global = _EmptyResponseHttpOverrides();
    });

    test('returns faked OK empty response for non-existing website', () async {
      // This is actually an instance of [FakeHttpClient].
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://non-existing-site.com'),
      );
      final response = await request.close();

      expect(response.statusCode, HttpStatus.ok);
      expect(response.contentLength, 0);
    });
  });
}

class _EmptyResponseHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(_) {
    return FakeHttpClient((request, client) {
      // The default response is an empty 200.
      return FakeHttpResponse();
    });
  }
}
