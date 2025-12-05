import 'package:flutter/widgets.dart';

class MQ {
  final BuildContext context;
  final Size size;
  final double height;
  final double width;

  MQ(this.context)
    : size = MediaQuery.of(context).size,
      height = MediaQuery.of(context).size.height,
      width = MediaQuery.of(context).size.width;

  double h(double fraction) => height * fraction;
  double w(double fraction) => width * fraction;
  double sp(double scale) => width * scale;
}
