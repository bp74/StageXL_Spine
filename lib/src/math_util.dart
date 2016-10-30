part of stagexl_spine;

/// multiplier for degrees to radians conversion
double _deg2rad = math.PI / 180.0;

/// multiplier for radians to degrees conversion
double _rad2deg = 180.0 / math.PI;

/// calculate cos based on degrees
double _cosDeg(double deg) => math.cos(_deg2rad * deg);

/// calculate sin based on degrees
double _sinDeg(double deg) => math.sin(_deg2rad * deg);

/// convert radians to degrees
double _toDeg(double rad) => _rad2deg * rad;

/// convert degrees to radians
double _toRad(double deg) => _deg2rad * deg;

/// Wrap within -180 degrees and 180 degrees
double _wrapRotation(double deg) => (180.0 + deg) % 360.0 - 180.0;
