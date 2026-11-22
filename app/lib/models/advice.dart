/// What the user should do now, optionally with a verified official contact.
class Advice {
  const Advice({required this.action, this.officialContact});

  final String action;
  final String? officialContact;

  factory Advice.fromJson(Map<String, dynamic> json) => Advice(
        action: json['action'] as String,
        officialContact: json['officialContact'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'action': action,
        'officialContact': officialContact,
      };
}
