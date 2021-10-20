import 'package:flutter/material.dart';
import 'dart:math' as math;

const double OFFSET_HEIGHT = 10;

class Display extends StatelessWidget {
  const Display({
    Key? key,
    required this.minValue,
    required this.maxValue,
    required this.currentValue,
    required this.units,
  }) : super(key: key);

  final double minValue;
  final double maxValue;
  final double currentValue;
  final String units;

  double getPointerAngle() {
    double pointerAngle = 0;
    if (currentValue > maxValue) {
      pointerAngle = math.pi;
    } else if (currentValue < minValue) {
      pointerAngle = 0;
    } else {
      pointerAngle =
          math.pi * (currentValue - minValue) / (maxValue - minValue);
    }
    return pointerAngle;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 150,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 100 + OFFSET_HEIGHT,
            child: ClipPath(
              child: Container(
                width: 200,
                height: 100 + OFFSET_HEIGHT,
                alignment: Alignment.bottomCenter,
                decoration: const BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.green,
                      Colors.yellow,
                      Colors.orange,
                      Colors.red,
                    ],
                    startAngle: math.pi,
                    endAngle: 2 * math.pi,
                  ),
                ),
              ),
              clipper: IndicatorClipper(concentricWidth: 20),
            ),
          ),
          Container(
            width: 200,
            height: 100 + OFFSET_HEIGHT,
            child: ClipPath(
              child: Container(
                width: 200,
                height: 100 + OFFSET_HEIGHT,
                alignment: Alignment.bottomCenter,
                color: Colors.grey,
              ),
              clipper: PointerClipper(
                  meterAngle: getPointerAngle(), concentricWidth: 20),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              currentValue.toString() + units,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              minValue.toString() + units,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              maxValue.toString() + units,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}

class IndicatorClipper extends CustomClipper<Path> {
  IndicatorClipper({required this.concentricWidth});
  final double concentricWidth;

  @override
  Path getClip(Size size) {
    Path path = Path();

    double bottomLeftX = 0;
    double bottomLeftY = size.height - OFFSET_HEIGHT;

    double bottomRightX = bottomLeftX + size.width;
    double bottomRightY = bottomLeftY;
    path.moveTo(bottomLeftX, bottomLeftY);
    path.arcToPoint(Offset(bottomRightX, bottomRightY),
        radius: Radius.circular(size.width / 2));
    path.lineTo(bottomRightX - concentricWidth, bottomRightY);
    path.arcToPoint(Offset(bottomLeftX + concentricWidth, bottomLeftY),
        radius: Radius.circular((size.width - 2 * concentricWidth) / 2),
        clockwise: false);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class PointerClipper extends CustomClipper<Path> {
  PointerClipper({required this.meterAngle, required this.concentricWidth});
  final double concentricWidth;
  final double meterAngle;
  @override
  Path getClip(Size size) {
    var path = Path();

    double bottomLeftX = 0;
    double bottomLeftY = size.height - OFFSET_HEIGHT;

    double bottomRightX = bottomLeftX + size.width;
    double bottomRightY = bottomLeftY;

    double bottomCenterX = (bottomLeftX + bottomRightX) / 2;
    double bottomCenterY = (bottomLeftY + bottomRightY) / 2 - 10;

    double displayRadius = size.width / 2;
    double indicatorWidth = 6;
    double centerRadius = displayRadius - indicatorWidth / 2;
    double outerRadius = centerRadius - indicatorWidth / 2;

    double centerBottomOffsetX = indicatorWidth * math.sin(meterAngle);
    double centerBottomOffsetY = indicatorWidth * math.cos(meterAngle);
    path.moveTo(bottomCenterX - centerBottomOffsetX / 2,
        bottomCenterY + centerBottomOffsetY / 2);

    // SHARP POINTER
    path.lineTo(displayRadius - outerRadius * math.cos(meterAngle),
        size.height - OFFSET_HEIGHT - outerRadius * math.sin(meterAngle));
    path.lineTo(bottomCenterX + centerBottomOffsetX / 2,
        bottomCenterY - centerBottomOffsetY / 2);
    path.arcToPoint(
        Offset(bottomCenterX - centerBottomOffsetX / 2,
            bottomCenterY + centerBottomOffsetY / 2),
        radius: Radius.circular(indicatorWidth / 2),
        rotation: math.pi);

    // RRECT

    // path.lineTo(
    //     displayRadius -
    //         outerRadius * math.cos(meterAngle) -
    //         centerBottomOffsetX / 2,
    //     size.height -
    //         OFFSET_HEIGHT -
    //         outerRadius * math.sin(meterAngle) +
    //         centerBottomOffsetY / 2);
    // path.arcToPoint(
    //     Offset(
    //         displayRadius -
    //             outerRadius * math.cos(meterAngle) +
    //             centerBottomOffsetX / 2,
    //         size.height -
    //             OFFSET_HEIGHT -
    //             outerRadius * math.sin(meterAngle) -
    //             centerBottomOffsetY / 2),
    //     radius: Radius.circular(indicatorWidth / 2),
    //     rotation: math.pi);
    // path.lineTo(bottomCenterX + centerBottomOffsetX / 2,
    //     bottomCenterY - centerBottomOffsetY / 2);
    // path.arcToPoint(
    //     Offset(bottomCenterX - centerBottomOffsetX / 2,
    //         bottomCenterY + centerBottomOffsetY / 2),
    //     radius: Radius.circular(indicatorWidth / 2),
    //     rotation: math.pi);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
