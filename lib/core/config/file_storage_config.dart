/// Where homework files (PDF / images) are stored: a Supabase Storage bucket.
///
/// Supabase is used instead of Firebase Storage because Firebase Storage needs
/// the paid Blaze plan. Set the two values below once (see supabase_setup.sql):
///
///   * SUPABASE_URL: Project Settings > API > Project URL
///   * SUPABASE_KEY: Project Settings > API Keys > Publishable key
///     (an older project's "anon" key works too)
///
/// Edit the defaultValue strings, or pass them at build time instead:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
///
/// The publishable / anon key is meant to be public, it is safe inside the app.
/// Never put the secret / service_role key here.
class FileStorageConfig {
  static const String _defaultUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zfawtwiqvqqjhfgoabmq.supabase.co',
  );
  static const String _defaultKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'YOUR-SUPABASE-PUBLISHABLE-KEY',
  );

  /// The settings the app uses.
  static const FileStorageConfig current = FileStorageConfig();

  final String url;
  final String key;
  final String bucket;

  const FileStorageConfig({
    this.url = _defaultUrl,
    this.key = _defaultKey,
    this.bucket = 'homework-files',
  });

  /// False until the placeholders above are replaced. Homework without files
  /// works either way, only attaching files needs this.
  bool get isConfigured =>
      url.startsWith('https://') &&
      !url.contains('YOUR-');

  String get _base =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  /// URL of the Edge Function that authorizes homework file operations.
  Uri get endpoint => Uri.parse('$_base/functions/v1/homework-files');

  /// Headers for every Storage request.
  ///
  /// The new "sb_publishable_..." keys are not JWTs and must only be sent in
  /// `apikey`. Older "anon" keys are JWTs (they start with "eyJ") and are also
  /// sent as the bearer token.
  Map<String, String> get headers => {
    'apikey': key,
    if (key.startsWith('eyJ')) 'Authorization': 'Bearer $key',
  };

  /// Endpoint for uploading (POST) or deleting (DELETE) one file.
  Uri objectUri(String path) =>
      Uri.parse('$_base/storage/v1/object/$bucket/$path');

  /// Link used to view the file. Works because the bucket is public.
  String publicUrl(String path) =>
      '$_base/storage/v1/object/public/$bucket/$path';
}
