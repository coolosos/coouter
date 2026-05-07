enum HttpMethod {
  GET,
  HEAD,
  POST,
  PUT,
  DELETE,
  // CONNECT,
  // OPTIONS,
  // TRACE,
  PATCH;

  String get method => name.toUpperCase();
}
