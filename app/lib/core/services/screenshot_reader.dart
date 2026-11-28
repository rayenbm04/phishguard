import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Picks a screenshot from the gallery and reads its text on the phone (SD3).
/// The image never leaves the phone: only the text the user confirms is checked.
class ScreenshotReader {
  const ScreenshotReader();

  /// Path of the chosen image, or null if the user cancelled.
  Future<String?> pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  /// Text found in the image ('' if none). ML Kit reads Latin script only (French, English).
  Future<String> readText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
