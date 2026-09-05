/// A value or a failure, never an exception crossing a layer boundary.
///
/// Used at every edge: storage, platform channels, file import, network. Domain
/// code returns [Result] so a caller cannot forget that failure is possible.
sealed class Result<T, E> {
  const Result();

  /// True when this holds a value.
  bool get isOk => this is Ok<T, E>;

  /// True when this holds a failure.
  bool get isErr => this is Err<T, E>;

  /// The value, or null when this is a failure.
  T? get valueOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  /// The failure, or null when this is a value.
  E? get errorOrNull => switch (this) {
        Ok() => null,
        Err(:final error) => error,
      };

  /// The value, or [fallback] when this is a failure.
  T valueOr(T fallback) => switch (this) {
        Ok(:final value) => value,
        Err() => fallback,
      };

  /// Transforms the value, leaving a failure untouched.
  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
        Ok(:final value) => Ok(transform(value)),
        Err(:final error) => Err(error),
      };

  /// Transforms the failure, leaving a value untouched.
  Result<T, F> mapErr<F>(F Function(E error) transform) => switch (this) {
        Ok(:final value) => Ok(value),
        Err(:final error) => Err(transform(error)),
      };

  /// Chains another fallible step onto a value.
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) next) =>
      switch (this) {
        Ok(:final value) => next(value),
        Err(:final error) => Err(error),
      };

  /// Collapses both sides into one type.
  R fold<R>(R Function(T value) onOk, R Function(E error) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };
}

/// A successful [Result].
final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      other is Ok<T, E> && other.value == value;

  @override
  int get hashCode => Object.hash('Ok', value);

  @override
  String toString() => 'Ok($value)';
}

/// A failed [Result].
final class Err<T, E> extends Result<T, E> {
  const Err(this.error);

  final E error;

  @override
  bool operator ==(Object other) =>
      other is Err<T, E> && other.error == error;

  @override
  int get hashCode => Object.hash('Err', error);

  @override
  String toString() => 'Err($error)';
}
