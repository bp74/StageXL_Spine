/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;

class Bone implements Updatable {

  final BoneData data;
  final Skeleton skeleton;
  final Bone parent;
  final List<Bone> children = new List<Bone>();

  double x = 0.0;
  double y = 0.0;
  double rotation = 0.0;
  double scaleX = 0.0;
  double scaleY = 0.0;
  double shearX = 0.0;
  double shearY = 0.0;

  double ax = 0.0;
  double ay = 0.0;
  double arotation = 0.0;
  double ascaleX = 0.0;
  double ascaleY = 0.0;
  double ashearX = 0.0;
  double ashearY = 0.0;
  bool appliedValid = false;

  double _a = 1.0;
  double _b = 0.0;
  double _c = 0.0;
  double _d = 1.0;
  double _worldX = 0.0;
  double _worldY = 0.0;

  bool _sorted = false;

  Bone(this.data, this.skeleton, this.parent) {
    if (data == null) throw new ArgumentError("data cannot be null.");
    if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");
    setToSetupPose();
  }

  /// Same as updateWorldTransform().
  /// This method exists for Bone to implement Updatable.
  ///
  void update() {
    updateWorldTransformWith(x, y, rotation, scaleX, scaleY, shearX, shearY);
  }

  /// Computes the world SRT using the parent bone and this bone's local SRT.

  void updateWorldTransform() {
    updateWorldTransformWith(x, y, rotation, scaleX, scaleY, shearX, shearY);
  }

	/// Computes the world SRT using the parent bone and the specified local SRT.
	void updateWorldTransformWith (
      double x, double y, double rotation,
      double scaleX, double scaleY, double shearX, double shearY) {

    ax = x;
    ay = y;
    arotation = rotation;
    ascaleX = scaleX;
    ascaleY = scaleY;
    ashearX = shearX;
    ashearY = shearY;
    appliedValid = true;

    double la = 0.0, lb = 0.0, lc = 0.0, ld = 0.0;
    double sin = 0.0, cos = 0.0;
    double s = 0.0;

    Bone parent = this.parent;
    if (parent == null) { // Root bone.
      la = scaleX * _cosDeg(rotation + shearX);
      lb = scaleY * _cosDeg(rotation + 90.0 + shearY);
      lc = scaleX * _sinDeg(rotation + shearX);
      ld = scaleY * _sinDeg(rotation + 90.0 + shearY);
      _a = la;
      _b = lb;
      _c = lc;
      _d = ld;
      _worldX = x + this.skeleton.x;
      _worldY = y + this.skeleton.y;
      return;
    }

    double pa = parent._a;
    double pb = parent._b;
    double pc = parent._c;
    double pd = parent._d;

    _worldX = pa * x + pb * y + parent._worldX;
    _worldY = pc * x + pd * y + parent._worldY;

    switch (this.data.transformMode) {
      case TransformMode.normal:
        la = scaleX * _cosDeg(rotation + shearX);
        lb = scaleY * _cosDeg(rotation + 90 + shearY);
        lc = scaleX * _sinDeg(rotation + shearX);
        ld = scaleY * _sinDeg(rotation + 90 + shearY);
        _a = pa * la + pb * lc;
        _b = pa * lb + pb * ld;
        _c = pc * la + pd * lc;
        _d = pc * lb + pd * ld;
        return;

      case TransformMode.onlyTranslation:
        _a = scaleX * _cosDeg(rotation + shearX);
        _b = scaleY * _cosDeg(rotation + 90 + shearY);
        _c = scaleX * _sinDeg(rotation + shearX);
        _d = scaleY * _sinDeg(rotation + 90 + shearY);
        break;

      case TransformMode.noRotationOrReflection:
        s = pa * pa + pc * pc;
        double prx = 0.0;
        if (s > 0.0001) {
          s = (pa * pd - pb * pc).abs() / s;
          pb = pc * s;
          pd = pa * s;
          prx = _toDeg(math.atan2(pc, pa));
        } else {
          pa = 0.0;
          pc = 0.0;
          prx = 90.0 - _toDeg(math.atan2(pd, pb));
        }
        double rx = rotation + shearX - prx;
        double ry = rotation + shearY - prx + 90;
        la = scaleX * _cosDeg(rx);
        lb = scaleY * _cosDeg(ry);
        lc = scaleX * _sinDeg(rx);
        ld = scaleY * _sinDeg(ry);
        _a = pa * la - pb * lc;
        _b = pa * lb - pb * ld;
        _c = pc * la + pd * lc;
        _d = pc * lb + pd * ld;
        break;

      case TransformMode.noScale:
      case TransformMode.noScaleOrReflection:
        cos = _cosDeg(rotation);
        sin = _sinDeg(rotation);
        double za = pa * cos + pb * sin;
        double zc = pc * cos + pd * sin;
        s = math.sqrt(za * za + zc * zc);
        if (s > 0.00001) s = 1 / s;
        za *= s;
        zc *= s;
        s = math.sqrt(za * za + zc * zc);
        double r = math.PI / 2 + math.atan2(zc, za);
        double zb = math.cos(r) * s;
        double zd = math.sin(r) * s;
        la = scaleX * _cosDeg(shearX);
        lb = scaleY * _cosDeg(90.0 + shearY);
        lc = scaleX * _sinDeg(shearX);
        ld = scaleY * _sinDeg(90.0 + shearY);
        _a = za * la + zb * lc;
        _b = za * lb + zb * ld;
        _c = zc * la + zd * lc;
        _d = zc * lb + zd * ld;

        if (this.data.transformMode != TransformMode.noScaleOrReflection ? pa * pd - pb * pc < 0 : false) {
          _b = -_b;
          _d = -_d;
        }
        break;
    }
	}

  void setToSetupPose() {
    x = this.data.x;
    y = this.data.y;
    rotation = this.data.rotation;
    scaleX = this.data.scaleX;
    scaleY = this.data.scaleY;
    shearX = this.data.shearX;
    shearY = this.data.shearY;
  }

  double get a => _a;
  double get b => _b;
  double get c => _c;
  double get d => _d;
  double get worldX => _worldX;
  double get worldY => _worldY;

  double get worldRotationX => _toDeg(math.atan2(_c, _a));
  double get worldRotationY => _toDeg(math.atan2(_d, _b));
  double get worldScaleX => math.sqrt(_a * _a + _c * _c);
  double get worldScaleY => math.sqrt(_b * _b + _d * _d);

  double worldToLocalRotationX() {
    Bone parent = this.parent;
    if (parent == null) return arotation;
    double pa = parent.a;
    double pb = parent.b;
    double pc = parent.c;
    double pd = parent.d;
    return _toDeg(math.atan2(pa * c - pc * a, pd * a - pb * c));
  }

  double worldToLocalRotationY() {
    Bone parent = this.parent;
    if (parent == null) return arotation;
    double pa = parent.a;
    double pb = parent.b;
    double pc = parent.c;
    double pd = parent.d;
    return _toDeg(math.atan2(pa * d - pc * b, pd * b - pb * d));
  }

  void rotateWorld (double degrees) {
    double a = this.a;
    double b = this.b;
    double c = this.c;
	  double d = this.d;
    double cos = _cosDeg(degrees);
    double	sin = _sinDeg(degrees);
    _a = cos * a - sin * c;
    _b = cos * b - sin * d;
    _c = sin * a + cos * c;
    _d = sin * b + cos * d;
    this.appliedValid = false;
  }

	/// Computes the individual applied transform values from the world transform.
  /// This can be useful to perform processing using the applied transform after
  /// the world transform has been modified directly (eg, by a constraint).
  ///
  /// Some information is ambiguous in the world transform, such as -1,-1 scale
  /// versus 180 rotation.

  void updateAppliedTransform() {

    this.appliedValid = true;
		Bone parent = this.parent;

    if (parent == null) {
      this.ax = worldX;
      this.ay = worldY;
      this.arotation = _toDeg(math.atan2(c, a));
      this.ascaleX = math.sqrt(a * a + c * c);
      this.ascaleY = math.sqrt(b * b + d * d);
      this.ashearX = 0.0;
      this.ashearY = _toDeg(math.atan2(a * b + c * d, a * d - b * c));
			return;
		}

		double pa = parent.a;
    double pb = parent.b;
    double pc = parent.c;
    double pd = parent.d;
    double pid = 1.0 / (pa * pd - pb * pc);

    double dx = worldX - parent.worldX;
    double dy = worldY - parent.worldY;
    this.ax = (dx * pd * pid - dy * pb * pid);
    this.ay = (dy * pa * pid - dx * pc * pid);

    double ia = pid * pd;
    double id = pid * pa;
    double ib = pid * pb;
    double ic = pid * pc;
    double ra = ia * a - ib * c;
    double rb = ia * b - ib * d;
    double rc = id * c - ic * a;
    double rd = id * d - ic * b;

		this.ashearX = 0.0;
    this.ascaleX = math.sqrt(ra * ra + rc * rc);

		if (this.scaleX > 0.0001) {
      double det = ra * rd - rb * rc;
			this.ascaleY = det /ascaleX;
      this.ashearY = _toDeg(math.atan2(ra * rb + rc * rd, det));
      this.arotation = _toDeg(math.atan2(rc, ra));
		} else {
			this.ascaleX = 0.0;
      this.ascaleY = math.sqrt(rb * rb + rd * rd);
      this.ashearY = 0.0;
      this.arotation = 90.0 - _toDeg(math.atan2(rd, rb));
		}
	}
	
  void worldToLocal (Float32List world) {
    double a = _a;
    double b = _b;
    double c = _c;
    double d = _d;
    double x = world[0] - _worldX;
    double y = world[1] - _worldY;
    world[0] = (x * d - y * b) / (a * d - b * c);
    world[1] = (y * a - x * c) / (a * d - b * c);
  }

  void localToWorld (Float32List local) {
    double localX = local[0];
    double localY = local[1];
    local[0] = localX * _a + localY * _b + _worldX;
    local[1] = localX * _c + localY * _d + _worldY;
  }

  String toString() => this.data.name;
}
