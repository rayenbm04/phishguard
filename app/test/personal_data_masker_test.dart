import 'package:flutter_test/flutter_test.dart';
import 'package:phishguard/core/models/models.dart';
import 'package:phishguard/core/services/personal_data_masker.dart';

void main() {
  const masker = PersonalDataMasker();

  test('masks Tunisian phone numbers in every common format', () {
    for (final phone in ['98123456', '98 123 456', '+216 98 123 456', '0021698123456', '22.123.456']) {
      final m = masker.mask('Appelez le $phone vite');
      expect(m.text, 'Appelez le [PHONE] vite', reason: phone);
      expect(m.maskedItems, 1);
    }
  });

  test('masks bank cards and account numbers', () {
    final m = masker.mask('Carte 4970 1012 3456 7890 et RIB 08 006 0123456789012 34');
    expect(m.text, 'Carte [CARD] et RIB [ACCOUNT]');
    expect(m.maskedItems, 2);
  });

  test('masks CIN numbers', () {
    final m = masker.mask('Mon CIN est 01234567.');
    expect(m.text, 'Mon CIN est [CIN].');
  });

  test('keeps links untouched, even with digits inside', () {
    const text = 'Payez ici: https://poste-tn.top/pay?id=98123456 avant ce soir';
    final m = masker.mask(text);
    expect(m.text, text);
    expect(m.maskedItems, 0);
  });

  test('keeps amounts and short numbers', () {
    const text = 'Your parcel is held. Pay 2.500 DT within 24 hours, code 4821.';
    expect(masker.mask(text).text, text);
  });

  test('detects the language', () {
    expect(masker.mask('Votre colis est bloqué').language, Language.french);
    expect(masker.mask('حسابك موقوف').language, Language.arabic);
    expect(masker.mask('Your account is locked').language, Language.english);
  });
}
