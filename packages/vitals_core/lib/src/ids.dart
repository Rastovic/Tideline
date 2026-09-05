import 'package:uuid/uuid.dart';

/// Identifier generation.
///
/// Rule 1 of `00-foundation/DATA-PORTABILITY.md`: UUID primary keys, never
/// autoincrement integers. Two devices both minting `id = 47` cannot be merged,
/// and that is unfixable once real users hold real history.
final class Ids {
  const Ids._();

  static const _uuid = Uuid();

  /// A time-ordered v7 id. The default for every row.
  ///
  /// v7 embeds a millisecond timestamp in its leading bits, so ids sort into
  /// creation order and an index over them stays local instead of scattering
  /// the way v4 does.
  ///
  /// **The ordering guarantee is millisecond-granular.** Two ids minted inside
  /// the same millisecond carry random sub-millisecond bits and may sort either
  /// way. Nothing may depend on id order to break such a tie: rows that need a
  /// definite order carry an explicit `sortOrder`, and rows that need a time
  /// carry an explicit timestamp.
  static String newId() => _uuid.v7();

  /// A random v4 id, for anything that must not leak a creation time.
  static String newRandomId() => _uuid.v4();

  /// True when [value] is a syntactically valid UUID of any version.
  static bool isValid(String value) => _uuidPattern.hasMatch(value);

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
}
