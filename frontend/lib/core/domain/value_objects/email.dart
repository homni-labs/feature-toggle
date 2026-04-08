class Email {
  final String value;

  Email(String raw) : value = raw.toLowerCase().trim() {
    if (raw.isEmpty ||
        !RegExp(r'^[\w.+-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(raw)) {
      throw FormatException('Invalid email: $raw');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Email && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
