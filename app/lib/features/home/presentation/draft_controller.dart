import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The message being prepared on the home screen. A text shared from another
/// app lands here and waits for the user to tap Check: nothing is analysed
/// before that.
@immutable
class Draft {
  const Draft({this.text = '', this.sourceApp, this.shared = false, this.revision = 0});

  final String text;

  /// Android package of the app the text was shared from.
  final String? sourceApp;

  /// True when the text came from the Android share menu.
  final bool shared;

  /// Changes each time the text is replaced from outside the text field
  /// (share, paste, screenshot), so the field knows to update itself.
  final int revision;
}

final draftProvider = NotifierProvider<DraftController, Draft>(DraftController.new);

class DraftController extends Notifier<Draft> {
  @override
  Draft build() => const Draft();

  /// Replaces the text from outside the field.
  void replace(String text, {String? sourceApp, bool shared = false}) {
    state = Draft(text: text, sourceApp: sourceApp, shared: shared, revision: state.revision + 1);
  }

  /// The user typed in the field.
  void edit(String text) {
    if (text == state.text) return;
    final keepSource = text.trim().isNotEmpty;
    state = Draft(
      text: text,
      sourceApp: keepSource ? state.sourceApp : null,
      shared: keepSource && state.shared,
      revision: state.revision,
    );
  }

  void clear() => replace('');
}
