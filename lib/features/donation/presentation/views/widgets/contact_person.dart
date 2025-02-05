class ContactPerson {
  final String name;
  final String phoneNumber;
  final String role;
  final String? bankAccount;
  final String? photoUrl;
  final String? additionalPaymentInfo;

  const ContactPerson({
    required this.name,
    required this.phoneNumber,
    required this.role,
    this.bankAccount,
    this.photoUrl,
    this.additionalPaymentInfo,
  });

  factory ContactPerson.fromMap(Map<String, dynamic> map) {
    return ContactPerson(
      name: map['name']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      bankAccount: map['bankAccount']?.toString(),
      photoUrl: map['photoUrl']?.toString(),
      additionalPaymentInfo: map['additionalPaymentInfo']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phoneNumber': phoneNumber,
        'role': role,
        'bankAccount': bankAccount,
        'photoUrl': photoUrl,
        'additionalPaymentInfo': additionalPaymentInfo,
      };

  String get formattedPhoneNumber {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length < 7) return phoneNumber;
    final displayNumber = cleanNumber.startsWith('2') && cleanNumber.length > 2
        ? cleanNumber.substring(1)
        : cleanNumber;
    return '\u200E${displayNumber.substring(0, 3)} ${displayNumber.substring(3, 6)} ${displayNumber.substring(6)}';
  }

  String get formattedAdditionalPaymentInfo {
    if (additionalPaymentInfo == null) return '';
    final cleanNumber = additionalPaymentInfo!.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length < 7) return additionalPaymentInfo!;
    final displayNumber = cleanNumber.startsWith('2') && cleanNumber.length > 2
        ? cleanNumber.substring(1)
        : cleanNumber;
    return '\u200E${displayNumber.substring(0, 3)} ${displayNumber.substring(3, 6)} ${displayNumber.substring(6)}';
  }

  ContactPerson copyWith({
    String? name,
    String? phoneNumber,
    String? role,
    String? bankAccount,
    String? photoUrl,
    String? additionalPaymentInfo,
  }) {
    if (name == null &&
        phoneNumber == null &&
        role == null &&
        bankAccount == null &&
        photoUrl == null &&
        additionalPaymentInfo == null) {
      return this;
    }
    return ContactPerson(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      bankAccount: bankAccount ?? this.bankAccount,
      photoUrl: photoUrl ?? this.photoUrl,
      additionalPaymentInfo:
          additionalPaymentInfo ?? this.additionalPaymentInfo,
    );
  }
}
