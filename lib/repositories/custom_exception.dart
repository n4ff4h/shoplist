class CustomException implements Exception {
  final String? message;

  // note: when setting default value the parameter must be enclosed with curly braces.
  const CustomException({this.message = 'Something went wrong!'});

  @override
  String toString() => 'CustomException { message: $message }';
}
