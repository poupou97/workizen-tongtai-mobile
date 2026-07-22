import 'package:image_picker/image_picker.dart';

/// Source of product photos for the Add/Edit form (WTM-69 AC2: product images
/// can be uploaded from the gallery or captured via the camera).
///
/// Kept as an interface so the form can be driven by a fake in tests (no
/// platform channels) and backed by [ImagePickerProductImageSource] on device.
/// Each method returns the picked file's local path, or `null` if the user
/// cancelled.
abstract interface class ProductImageSource {
  /// Pick an existing photo from the device gallery ("upload").
  Future<String?> pickFromGallery();

  /// Capture a new photo with the camera.
  Future<String?> captureFromCamera();
}

/// Production [ProductImageSource] backed by the `image_picker` plugin.
class ImagePickerProductImageSource implements ProductImageSource {
  ImagePickerProductImageSource([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// JPEG quality (0–100) applied to picked/captured images to keep the on-device
  /// files small; product thumbnails do not need full-resolution fidelity.
  static const int _imageQuality = 85;

  @override
  Future<String?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: _imageQuality,
    );
    return file?.path;
  }

  @override
  Future<String?> captureFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: _imageQuality,
    );
    return file?.path;
  }
}
