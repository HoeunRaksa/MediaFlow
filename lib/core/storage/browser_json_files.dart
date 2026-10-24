import 'dart:convert';

import 'package:web/web.dart' as web;

/// Browser-backed JSON records. Uses the same seeding and migrations as desktop,
/// but keeps Safari data separate from the Windows application's files.
class Directory {
  const Directory(this.path);
  final String path;
  Future<bool> exists() async => true;
  Future<Directory> create({bool recursive = false}) async => this;
}

class File {
  const File(this.path);
  final String path;
  String get _key => 'material_quote_pro:$path';
  Directory get parent => Directory(path.substring(0, path.lastIndexOf('/')));
  Future<bool> exists() async => web.window.localStorage.getItem(_key) != null;
  Future<String> readAsString({Encoding encoding = utf8}) async =>
      web.window.localStorage.getItem(_key) ?? '';
  Future<File> writeAsString(String value, {Encoding encoding = utf8}) async {
    web.window.localStorage.setItem(_key, value);
    return this;
  }
}

class Platform {
  static const environment = <String, String>{};
  static const isWindows = false;
}
