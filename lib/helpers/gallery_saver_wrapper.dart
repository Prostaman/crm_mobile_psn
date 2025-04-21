import 'package:gallery_saver/gallery_saver.dart';
import 'package:synchronized/synchronized.dart';

/// A wrapper class aground image saving process for preventing the deadlocks
/// on the plugin side.

class GallerySaverWrapper {
  GallerySaverWrapper._() : _lock = Lock();
  static final _instance = GallerySaverWrapper._();
  static GallerySaverWrapper get instance => _instance;
  static const String nameOfAlbum = "Поехали с нами";

  final Lock _lock;

  /// Helps to complete [_saveImageToGallery] in sync.
  Future<void> saveImageToGallery(String filePath) async {
    await _lock.synchronized(
      () => _saveImageToGallery(filePath),
    );
  }

  /// Saves the image to the gallery.
  Future<void> _saveImageToGallery(String filePath) async {
    await GallerySaver.saveImage(filePath, albumName: nameOfAlbum);
  }

  /// Helps to complete [_saveVideoToGallery] in sync.
  Future<void> saveVideoToGallery(String filePath) async {
    await _lock.synchronized(
      () => _saveVideoToGallery(filePath),
    );
  }

  /// Saves the video to the gallery.
  Future<void> _saveVideoToGallery(String filePath) async {
    await GallerySaver.saveVideo(filePath, albumName: nameOfAlbum);
  }
}
