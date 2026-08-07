class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message ($cause)';
}

class AnalysisException extends AppException {
  const AnalysisException(super.message, {super.cause});
}

class CatalogueException extends AppException {
  const CatalogueException(super.message, {super.cause});
}

class PersistenceException extends AppException {
  const PersistenceException(super.message, {super.cause});
}
