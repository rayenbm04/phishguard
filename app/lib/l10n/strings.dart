import 'package:flutter/widgets.dart';

import '../models/models.dart';

/// Every text of the interface, in French, Arabic and English.
/// Usage: `S.of(context).checkButton`.
class S {
  const S(this.language);

  final Language language;

  static const supported = [Language.french, Language.arabic, Language.english];

  static S of(BuildContext context) => S(languageOf(Localizations.localeOf(context)));

  static Language languageOf(Locale locale) => switch (locale.languageCode) {
        'ar' => Language.arabic,
        'en' => Language.english,
        _ => Language.french,
      };

  String _t(String fr, String ar, String en) => switch (language) {
        Language.french => fr,
        Language.arabic => ar,
        Language.english => en,
      };

  /// The name of a language, always written in that language.
  static String languageName(Language l) => switch (l) {
        Language.french => 'Français',
        Language.arabic => 'العربية',
        Language.english => 'English',
      };

  // ---------- Home ----------
  String get homeHeadline => _t('Un message bizarre ?', 'رسالة مشبوهة؟', 'Got a strange message?');
  String get homeSubtitle => _t(
        'Demandez un deuxième avis avant de cliquer, de payer ou de rappeler.',
        'اطلب رأيا ثانيا قبل أن تضغط أو تدفع أو تتصل.',
        'Get a second opinion before you click, pay or call back.',
      );
  String get pasteAndCheck => _t('Coller et analyser', 'الصق وحلّل', 'Paste and analyse');
  String get typeMessage =>
      _t('Écrire un message ou un lien', 'اكتب رسالة أو رابطا', 'Type a message or link');
  String get checkScreenshot =>
      _t('Vérifier une capture d\'écran', 'افحص لقطة شاشة', 'Check a screenshot');
  String get shareTip => _t(
        'Plus rapide : dans WhatsApp, SMS ou Gmail, appuyez longuement sur le message, '
            'puis Partager et choisissez PhishGuard.',
        'أسرع: في واتساب أو الرسائل أو جيميل، اضغط مطولا على الرسالة ثم مشاركة واختر PhishGuard.',
        'Faster: in WhatsApp, SMS or Gmail, long-press the message, tap Share, then choose PhishGuard.',
      );
  String get recentChecks =>
      _t('Vérifications récentes', 'آخر عمليات الفحص', 'Recent checks');
  String get historyEmpty => _t(
        'Vos vérifications apparaîtront ici. Elles restent sur ce téléphone.',
        'ستظهر عمليات الفحص هنا، وتبقى على هذا الهاتف.',
        'Your checks will appear here. They stay on this phone.',
      );
  String get settings => _t('Réglages', 'الإعدادات', 'Settings');

  // ---------- Screenshot ----------
  String get readingImage =>
      _t('Lecture de l\'image…', 'جارٍ قراءة الصورة…', 'Reading the image…');
  String get noTextInImage => _t(
        'Aucun texte trouvé dans cette image. Les captures en arabe ne sont pas encore lues : '
            'collez plutôt le texte du message.',
        'لم يُعثر على نص في هذه الصورة. لا تُقرأ اللقطات المكتوبة بالعربية بعد: الصق نص الرسالة بدلا من ذلك.',
        'No text found in this image. Arabic screenshots cannot be read yet: paste the text of the '
            'message instead.',
      );
  String get imageError => _t('Impossible de lire cette image.', 'تعذّرت قراءة هذه الصورة.',
      'This image could not be read.');
  String get textFromScreenshot => _t(
        'Texte lu dans la capture : vérifiez-le, puis lancez la vérification.',
        'النص المقروء من اللقطة: راجعه ثم ابدأ الفحص.',
        'Text read from the screenshot: check it, then start the check.',
      );

  // ---------- Check ----------
  String get checkTitle => _t('Vérifier un message', 'افحص رسالة', 'Check a message');
  String get messageHint => _t(
        'Collez ici le message, l\'e-mail ou le lien',
        'الصق هنا الرسالة أو البريد أو الرابط',
        'Paste the message, email or link here',
      );
  String get sharedWithApp =>
      _t('Partagé avec PhishGuard', 'تمت المشاركة مع PhishGuard', 'Shared with PhishGuard');
  String sharedFrom(String app) =>
      _t('Partagé depuis $app', 'تمت المشاركة من $app', 'Shared from $app');
  String get privacyNoteNone => _t(
        'Les numéros de téléphone, de carte et de CIN sont masqués avant que le message quitte votre téléphone.',
        'تُخفى أرقام الهاتف والبطاقة وبطاقة التعريف قبل أن تغادر الرسالة هاتفك.',
        'Phone, card and ID numbers are hidden before the message leaves your phone.',
      );
  String privacyNoteCount(int n) => _t(
        n == 1
            ? '1 numéro personnel (téléphone, carte ou CIN) sera masqué avant l\'envoi.'
            : '$n numéros personnels (téléphone, carte ou CIN) seront masqués avant l\'envoi.',
        'سيتم إخفاء $n من الأرقام الشخصية (هاتف أو بطاقة أو بطاقة تعريف) قبل الإرسال.',
        n == 1
            ? '1 personal number (phone, card or ID) will be hidden before the message leaves your phone.'
            : '$n personal numbers (phone, card or ID) will be hidden before the message leaves your phone.',
      );
  String get checkButton => _t('Vérifier ce message', 'افحص هذه الرسالة', 'Check this message');
  String get checking => _t('Vérification…', 'جارٍ الفحص…', 'Checking…');
  String get tryAgain => _t('Réessayer', 'أعد المحاولة', 'Try again');

  // ---------- Errors ----------
  String get errEmptyTitle => _t('Rien à vérifier', 'لا يوجد ما يُفحص', 'Nothing to check');
  String get errEmptyBody => _t('Collez ou écrivez d\'abord un message.',
      'الصق رسالة أو اكتبها أولا.', 'Paste or type a message first.');
  String get errOfflineTitle => _t(
        'Vous êtes hors ligne. N\'ouvrez pas encore le lien.',
        'أنت غير متصل بالإنترنت. لا تفتح الرابط الآن.',
        'You\'re offline. Don\'t open the link yet.',
      );
  String get errOfflineBody => _t('Connectez-vous à Internet, puis réessayez.',
      'اتصل بالإنترنت ثم أعد المحاولة.', 'Connect to the internet, then try again.');
  String get errServerTitle => _t(
        'PhishGuard est injoignable pour le moment.',
        'تعذّر الوصول إلى PhishGuard حاليا.',
        'PhishGuard can\'t be reached right now.',
      );
  String get errServerBody => _t(
        'Réessayez dans un instant. En attendant, méfiez-vous du message.',
        'أعد المحاولة بعد قليل، وإلى ذلك الحين تعامل مع الرسالة بحذر.',
        'Try again in a moment. Until then, treat the message with care.',
      );

  // ---------- Result ----------
  String get resultTitle => _t('Résultat', 'النتيجة', 'Result');
  String get why => _t('Pourquoi', 'لماذا', 'Why');
  String get whatToDo => _t('Que faire maintenant', 'ماذا تفعل الآن', 'What to do now');
  String officialContact(String c) =>
      _t('Contact officiel : $c', 'جهة رسمية: $c', 'Official contact: $c');
  String source(String s) => _t('Source : $s', 'المصدر: $s', 'Source: $s');
  String checkedOn(String d) => _t('Vérifié le $d', 'تم الفحص في $d', 'Checked on $d');
  String get riskOutOf100 => _t('risque / 100', 'الخطر / 100', 'risk / 100');
  String get back => _t('Retour', 'رجوع', 'Back');
  String get checkAnother =>
      _t('Vérifier un autre message', 'افحص رسالة أخرى', 'Check another message');

  String levelLabel(VerdictLevel level) => switch (level) {
        VerdictLevel.fraudulent => _t('Arnaque', 'احتيال', 'Scam'),
        VerdictLevel.suspicious => _t('Suspect', 'مشبوه', 'Suspicious'),
        VerdictLevel.safe => _t('Semble sûr', 'يبدو آمنا', 'Looks safe'),
        VerdictLevel.unsure => _t('Incertain', 'غير مؤكد', 'Unsure'),
      };

  // ---------- Onboarding ----------
  String get onboardingTitle => _t(
        'Un deuxième avis sur n\'importe quel message',
        'رأي ثانٍ في أي رسالة',
        'A second opinion on any message',
      );
  String get onboardingIntro => _t(
        'Avant de commencer, voici comment PhishGuard protège votre vie privée :',
        'قبل البدء، إليك كيف يحمي PhishGuard خصوصيتك:',
        'Before you start, here is how PhishGuard protects your privacy:',
      );
  List<String> get privacyPromises => [
        _t(
          'Les numéros de téléphone, de carte et de CIN sont masqués sur votre téléphone, avant toute analyse.',
          'تُخفى أرقام الهاتف والبطاقة وبطاقة التعريف على هاتفك قبل أي تحليل.',
          'Phone, card and ID numbers are hidden on your phone, before any analysis.',
        ),
        _t(
          'Seul le texte masqué est envoyé pour l\'analyse. Aucun compte n\'est créé.',
          'يُرسل النص المخفي فقط للتحليل، ولا يتم إنشاء أي حساب.',
          'Only the masked text is sent for analysis. No account is created.',
        ),
        _t(
          'Votre historique reste sur ce téléphone, et vous pouvez l\'effacer à tout moment.',
          'يبقى سجلك على هذا الهاتف، ويمكنك مسحه في أي وقت.',
          'Your history stays on this phone, and you can clear it at any time.',
        ),
      ];
  String get iAgree => _t('J\'accepte ces conditions', 'أوافق على هذه الشروط', 'I agree');
  String get continueLabel => _t('Continuer', 'متابعة', 'Continue');
  String get chooseLanguage => _t('Choisissez votre langue', 'اختر لغتك', 'Choose your language');
  String get startChecking => _t('Commencer', 'ابدأ', 'Start checking');

  // ---------- Settings ----------
  String get languageLabel => _t('Langue', 'اللغة', 'Language');
  String get clearHistory => _t('Effacer l\'historique', 'مسح السجل', 'Clear history');
  String get clearHistoryQuestion => _t(
        'Effacer toutes les vérifications enregistrées sur ce téléphone ?',
        'هل تريد مسح جميع عمليات الفحص المحفوظة على هذا الهاتف؟',
        'Clear all checks saved on this phone?',
      );
  String get cancel => _t('Annuler', 'إلغاء', 'Cancel');
  String get clear => _t('Effacer', 'مسح', 'Clear');
  String get historyCleared => _t('Historique effacé', 'تم مسح السجل', 'History cleared');
  String get privacy => _t('Confidentialité', 'الخصوصية', 'Privacy');
  String get version => _t('Version', 'الإصدار', 'Version');
}
