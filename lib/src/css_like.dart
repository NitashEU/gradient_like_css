import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gradient_like_css/src/colors_and_stops.dart';
import 'package:gradient_like_css/src/web_colors.dart';

class CssLike {
  /// Create linear gradients with CSS-like coding.
  /// For example, the following code.
  ///
  /// ```dart
  /// BoxDecoration(
  ///   gradient: CssLike
  ///     .linearGradient(-225, ['#69EACB', '#EACCF8 48%', "#6654F1"]),
  /// );
  ///```
  ///
  /// The [angleOrEndAlignment] argument is valid only for the [double] or
  /// [Alignment] type.
  ///
  /// The [colorStopList] argument is a space-separated list of String
  /// containing colors and stops.
  /// The [colorStopList] argument must not be null. Colors allow web color
  /// names or color codes that start with "#". Stops allow percentage strings
  /// like "12.34%".
  ///
  static LinearGradient linearGradient(Object angleOrEndAlignment, List<String> colorStopList) {
    final endAlignment = _getEndAlignment(angleOrEndAlignment);
    final colorsAndStops = _getColorsAndStops(colorStopList);

    return LinearGradient(
      begin: -endAlignment,
      end: endAlignment,
      colors: colorsAndStops.colors,
      stops: colorsAndStops.stops,
    );
  }

  static Alignment _getEndAlignment(Object? angleOrEndAlignment) {
    if (angleOrEndAlignment == null) {
      return Alignment.bottomCenter;
    } else if (angleOrEndAlignment is num) {
      final angle = angleOrEndAlignment.toDouble();
      return _degreesToAlignment(angle - 90.0);
    } else if (angleOrEndAlignment is Alignment) {
      return angleOrEndAlignment;
    } else {
      throw const FormatException(
          // ignore: lines_longer_than_80_chars
          'The "angleOrEndAlignment" argument is valid only for the "double" or "Alignment" type.');
    }
  }

  static ColorsAndStops _getColorsAndStops(List<String> colorStopList) {
    final colors = <Color>[];
    final stops = <double>[];

    if (colorStopList.isEmpty) {
      throw const FormatException(
          // ignore: lines_longer_than_80_chars
          'The "colorStopList" argument can be set up to three, separated by spaces, such as "yellow 40% 60%".');
    }

    for (final param in colorStopList) {
      String? colorCode, percentage1, percentage2;

      final splitParam = param.split(' ');
      if (splitParam.length > 0) {
        colorCode = splitParam[0];
      }
      if (splitParam.length > 1) {
        percentage1 = splitParam[1];
      }
      if (splitParam.length > 2) {
        percentage2 = splitParam[2];
      }
      if (splitParam.length == 0 || splitParam.length > 3 || colorCode == null) {
        throw const FormatException(
            // ignore: lines_longer_than_80_chars
            'The "colorStopList" argument can be set up to three, separated by spaces, such as "yellow 40% 60%".');
      }

      final color = _codeToColor(colorCode);
      final stop1 = _percentageStringToStop(percentage1);
      if ((percentage2 ?? '').isEmpty) {
        colors.add(color);
        stops.add(stop1);
      } else {
        colors
          ..add(color)
          ..add(color);
        stops
          ..add(stop1)
          ..add(_percentageStringToStop(percentage2));
      }
    }

    if (stops.first.isNaN) {
      stops.first = 0.0;
    }
    if (stops.last.isNaN) {
      stops.last = 1.0;
    }
    stops.asMap().forEach((index, stop) {
      if (stop.isNaN) {
        final start = index;
        var end = start;
        while (stops[end + 1].isNaN) {
          end++;
        }
        final previousStop = stops[start - 1];
        final nextStop = stops[end + 1];
        final range = end - index + 1;
        final separation = (nextStop - previousStop) / (range + 1);

        for (var i = 0; i < range; i++) {
          stops[index + i] = double.parse((previousStop + separation * (i + 1)).toStringAsPrecision(8));
        }
      }
    });
    return ColorsAndStops(colors, stops);
  }

  static double _percentageStringToStop(String? percentageString) {
    if (percentageString == null || percentageString.isEmpty) {
      return double.nan;
    }
    if (!percentageString.endsWith('%')) {
      throw const FormatException('Bad stop format (Allow percentage strings like "12.34%").');
    }

    try {
      final stop = double.parse(percentageString.replaceAll('%', '')) / 100;
//      assert(0.0 <= stop && stop <= 1.0);
      return stop;
    } on Exception {
      throw const FormatException('Bad stop format (Allow percentage strings like "12.34%").');
    }
  }

  static Color _codeToColor(String code) {
    final webColor = WebColors.of(code);
    if (webColor != null) {
      return webColor.color;
    }
    return Color(_makeHexCode(code));
  }

  static int _makeHexCode(String code) {
    final hexColorCodeExp = RegExp(r'^#([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    if (hexColorCodeExp.allMatches(code).length != 1) {
      throw const FormatException(
          // ignore: lines_longer_than_80_chars
          'Bad color code format (Allow web color name or color code that start with "#").');
    }

    String hexCode;
    if (code.length == 9) {
      final a1 = code[1];
      final a2 = code[2];
      final r1 = code[3];
      final r2 = code[4];
      final g1 = code[5];
      final g2 = code[6];
      final b1 = code[7];
      final b2 = code[8];
      hexCode = '0x$a1$a2$r1$r2$g1$g2$b1$b2';
    } else if (code.length == 4) {
      final r = code[1];
      final g = code[2];
      final b = code[3];
      hexCode = '0xFF$r$r$g$g$b$b';
    } else {
      hexCode = code.replaceFirst('#', '0xFF');
    }

    return int.parse(hexCode);
  }

  static Alignment _degreesToAlignment(double degrees) {
    final x = _x(degrees);
    final y = _y(degrees);

    if ((0.0 < x && x < 1.0) || (0.0 < y && y < 1.0)) {
      final magnification = (1 / x) < (1 / y) ? (1 / x) : (1 / y);
      return Alignment(x, y) * magnification;
    } else {
      return Alignment(x, y);
    }
  }

  static double _x(double degrees) {
    final radians = degrees / 180.0 * math.pi;
    return double.parse(math.cos(radians).toStringAsPrecision(8));
  }

  static double _y(double degrees) {
    final radians = degrees / 180.0 * math.pi;
    return double.parse(math.sin(radians).toStringAsPrecision(8));
  }
}
