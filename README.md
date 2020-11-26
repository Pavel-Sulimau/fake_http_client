# fake_http_client
A package for faking Dart HttpClient's responses.

## Example
The following example forces all HTTP requests to return a
successful empty response in a test environment.  No actual HTTP requests will be performed.

```dart
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(_) {
    return FakeHttpClient((request, client) {
        // the default response is an empty 200.
        return HttpTestResponse();
    });
  }
}

void main() {
  group('HttpClient', () {
    setUp(() {
      // overrides all HttpClients.
      HttpOverrides.global = MyHttpOverrides();
    });

    test('returns OK', () async {
      // this is actually an instance of [FakeHttpClient].
      final client = HttpClient();
      final request = client.getUrl(Uri.https('google.com'));
      final response = await request.close();

      expect(response.statusCode, HttpStatus.ok);
    });
  });
}
```
