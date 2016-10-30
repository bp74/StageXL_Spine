part of stagexl_spine;

double _deg2rad = math.PI / 180.0;
double _rad2deg = 180.0 / math.PI;

double _cosDeg(double deg) => math.cos(_deg2rad * deg);
double _sinDeg(double deg) => math.sin(_deg2rad * deg);

double _toDeg(double rad) => _rad2deg * rad;
double _toRad(double deg) => _deg2rad * deg;

/// Wrap within -180 and 180 degrees.
double _wrapRotation(double deg) {
  return deg - 360.0 * (deg / 360.0).round();
  //return deg - (16384 - (16384.499999999996 - deg / 360).toInt()) * 360;
}
