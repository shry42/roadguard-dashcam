import 'dart:io';

import 'package:gal/gal.dart';

class GallerySaveService {
  GallerySaveService._();
  static final GallerySaveService instance = GallerySaveService._();

  Future<bool> ensureAccess() async {
    if (await Gal.hasAccess()) return true;
    return Gal.requestAccess();
  }

  Future<bool> saveVideo(File file) async {
    if (!file.existsSync()) return false;
    if (!await ensureAccess()) return false;
    await Gal.putVideo(file.path);
    return true;
  }

  Future<bool> saveImage(File file) async {
    if (!file.existsSync()) return false;
    if (!await ensureAccess()) return false;
    await Gal.putImage(file.path);
    return true;
  }
}
