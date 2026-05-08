import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Logger instance = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 8,
      lineLength: 110,
      colors: true,
      printEmojis: false,
      printTime: true,
    ),
  );
}

