/// Lightweight functional result type used across service boundaries,
/// keeping failures explicit without throwing through layers.
sealed class Result<T> {
  const Result();
  R when<R>({required R Function(T) ok, required R Function(AppFailure) err}) =>
      switch (this) {
        Ok<T>(:final value) => ok(value),
        Err<T>(:final failure) => err(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}

class AppFailure {
  const AppFailure(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => 'AppFailure($message)';
}
