class Slug {
  final String value;

  Slug(String raw) : value = raw.trim() {
    if (raw.trim().isEmpty) {
      throw FormatException('Slug must not be empty');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Slug && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
