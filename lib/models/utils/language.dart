class Language {
  const Language({required this.name, required this.code});

  final String name;
  final String code;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
    };
  }

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      name: map['name'] ?? '',
      code: map['code'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is Language && other.name == name && other.code == code;
  }

  @override
  int get hashCode => name.hashCode ^ code.hashCode;
}

const List<Language> languages = [
  Language(name: 'English', code: 'gb'),
  Language(name: 'Greek', code: 'gr'),
  Language(name: 'German', code: 'de'),
  Language(name: 'Spanish', code: 'es'),
  Language(name: 'French', code: 'fr'),
  Language(name: 'Italian', code: 'it'),
];

