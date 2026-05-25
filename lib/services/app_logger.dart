import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  final List<_LogEntry> _entries = [];
  File? _logFile;

  List<_LogEntry> get entries => List.unmodifiable(_entries);

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/rentease_logs');
      if (!await logDir.exists()) await logDir.create(recursive: true);
      _logFile = File('${logDir.path}/rentease_${_dateStamp()}.log');
      await _logFile!.writeAsString(
        '=== RentEase App Log — ${DateTime.now()} ===\n',
        mode: FileMode.append,
      );
      info('Logger', 'Log file: ${_logFile!.path}');
    } catch (e) {
      debugPrint('Logger init error: $e');
    }
  }

  void info(String tag, String message, [dynamic data]) {
    final entry = _LogEntry(level: 'INFO', tag: tag, message: message, data: data);
    _add(entry);
    _logger.i('[$tag] $message${data != null ? '\n$data' : ''}');
  }

  void warning(String tag, String message, [dynamic data]) {
    final entry = _LogEntry(level: 'WARN', tag: tag, message: message, data: data);
    _add(entry);
    _logger.w('[$tag] $message${data != null ? '\n$data' : ''}');
  }

  void error(String tag, String message, [dynamic error, StackTrace? stack]) {
    final entry = _LogEntry(level: 'ERROR', tag: tag, message: message, data: error);
    _add(entry);
    _logger.e('[$tag] $message', error: error, stackTrace: stack);
  }

  void api(String method, String url, int status, dynamic responseBody) {
    final ok = status >= 200 && status < 300;
    final msg = '$method $url → $status';
    final entry = _LogEntry(
      level: ok ? 'API_OK' : 'API_ERR',
      tag: 'API',
      message: msg,
      data: responseBody,
    );
    _add(entry);
    if (ok) {
      _logger.i('[API] $msg');
    } else {
      _logger.w('[API] $msg\n$responseBody');
    }
  }

  void nav(String screen) {
    info('NAV', 'Navigate → $screen');
  }

  void _add(_LogEntry entry) {
    _entries.add(entry);
    _writeToFile(entry);
  }

  void _writeToFile(_LogEntry entry) {
    if (_logFile == null) return;
    final dataStr = entry.data != null ? '\n  ${entry.data}' : '';
    final line = '[${entry.timestamp}] [${entry.level}] [${entry.tag}] ${entry.message}$dataStr\n';
    _logFile!.writeAsString(line, mode: FileMode.append).catchError((_) => _logFile!);
  }

  String _dateStamp() {
    final now = DateTime.now();
    return '${now.year}${_p(now.month)}${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}';
  }

  String _p(int v) => v.toString().padLeft(2, '0');

  String get logFilePath => _logFile?.path ?? 'Not initialized';
}

class _LogEntry {
  final String level;
  final String tag;
  final String message;
  final dynamic data;
  final String timestamp;

  _LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    this.data,
  }) : timestamp = DateTime.now().toIso8601String();
}
