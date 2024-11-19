# fake_http_client

A package for faking Dart/Flutter HttpClient's responses.

It is handy for integration tests. Also it may help a lot during app development with an unstable back-end.

## Example

The following example forces all HTTP requests to return a
successful empty response in a test environment.  No actual HTTP requests will be performed.

```dart
class _EmptyResponseHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(_) => FakeHttpClient(
        // The default fake response is an empty 200.
        (request, client) => FakeHttpResponse(),
      );
}

void main() {
  group('HttpClient', () {
    setUp(() {
      // Overrides all HttpClients.
      HttpOverrides.global = _EmptyResponseHttpOverrides();
    });

    test('returns faked OK empty response for non-existing website', () async {
      // This is actually an instance of [FakeHttpClient].
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://non-existing-site.com'));
      final response = await request.close();

      expect(response.statusCode, HttpStatus.ok);
      expect(response.contentLength, 0);
    });
  });
}
```
