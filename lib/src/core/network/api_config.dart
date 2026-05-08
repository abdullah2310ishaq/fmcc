class ApiConfig {
  const ApiConfig._();

  /// From Postman collection:
  /// `http://aphasia.careho.pk/api/...`
  ///
  /// The server redirects HTTP → HTTPS (301), so we default to HTTPS to avoid
  /// redirection failures in strict HTTP clients.
  static const defaultBaseUrl = 'https://aphasia.careho.pk';
}

