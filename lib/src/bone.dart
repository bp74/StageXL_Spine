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
  final Bone? parent;
  final List<Bone> children = [];

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
    setToSetupPose();
  }

  /// Same as updateWorldTransform().
  /// This method exists for Bone to implement Updatable.

  @override
  void update() {
    updateWorldTransformWith(x, y, rotation, scaleX, scaleY, shearX, shearY);
  }

  /// Computes the world SRT using the parent bone and this bone's local SRT.

  void updateWorldTransform() {
    updateWorldTransformWith(x, y, rotation, scaleX, scaleY, shearX, shearY);
  }

  /// Computes the world SRT using the parent bone and the specified local SRT.
  void updateWorldTransformWith(double x, double y, double rotation, double scaleX, double scaleY,
      double shearX, double shearY) {
    ax = x;
    ay = y;
    arotation = rotation;
    ascaleX = scaleX;
    ascaleY = scaleY;
    ashearX = shearX;
    ashearY = shearY;
    appliedValid = true;

    Bone? parent = this.parent;
    if (parent == null) {
      // Root bone.
      _a = scaleX * _cosDeg(rotation + shearX);
      _b = scaleY * _cosDeg(rotation + 90.0 + shearY);
      _c = scaleX * _sinDeg(rotation + shearX);
      _d = scaleY * _sinDeg(rotation + 90.0 + shearY);
      _worldX = x + skeleton.x;
      _worldY = y + skeleton.y;
      return;
    }

    double pa = parent.a;
    double pb = parent.b;
    double pc = parent.c;
    double pd = parent.d;

    _worldX = pa * x + pb * y + parent.worldX;
    _worldY = pc * x + pd * y + parent.worldY;

    switch (data.transformMode) {
      case TransformMode.normal:
        double la = scaleX * _cosDeg(rotation + shearX);
        double lb = scaleY * _cosDeg(rotation + 90 + shearY);
        double lc = scaleX * _sinDeg(rotation + shearX);
        double ld = scaleY * _sinDeg(rotation + 90 + shearY);
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
        double s = pa * pa + pc * pc;
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
        double ry = rotation + shearY - prx + 90.0;
        double la = scaleX * _cosDeg(rx);
        double lb = scaleY * _cosDeg(ry);
        double lc = scaleX * _sinDeg(rx);
        double ld = scaleY * _sinDeg(ry);
        _a = pa * la - pb * lc;
        _b = pa * lb - pb * ld;
        _c = pc * la + pd * lc;
        _d = pc * lb + pd * ld;
        break;

      case TransformMode.noScale:
      case TransformMode.noScaleOrReflection:
        double cos = _cosDeg(rotation);
        double sin = _sinDeg(rotation);
        double za = pa * cos + pb * sin;
        double zc = pc * cos + pd * sin;
        double s = math.sqrt(za * za + zc * zc);
        if (s > 0.00001) s = 1.0 / s;
        za *= s;
        zc *= s;
        s = math.sqrt(za * za + zc * zc);
        double r = math.pi / 2.0 + math.atan2(zc, za);
        double zb = math.cos(r) * s;
        double zd = math.sin(r) * s;
        double la = scaleX * _cosDeg(shearX);
        double lb = scaleY * _cosDeg(90.0 + shearY);
        double lc = scaleX * _sinDeg(shearX);
        double ld = scaleY * _sinDeg(90.0 + shearY);
        if (data.transformMode != TransformMode.noScaleOrReflection) {
          if (pa * pd - pb * pc < 0.0) {
            zb = -zb;
            zd = -zd;
          }
        }
        _a = za * la + zb * lc;
        _b = za * lb + zb * ld;
        _c = zc * la + zd * lc;
        _d = zc * lb + zd * ld;
        break;
    }
  }

  void setToSetupPose() {
    x = data.x;
    y = data.y;
    rotation = data.rotation;
    scaleX = data.scaleX;
    scaleY = data.scaleY;
    shearX = data.shearX;
    shearY = data.shearY;
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
    Bone? parent = this.parent;
    if (parent == null) return arotation;
    double pa = parent.a;
    double pb = parent.b;
    double pc = parent.c;
    double pd = parent.d;
    return _toDeg(math.atan2(pa * c - pc * a, pd * a - pb * c));
  }

  double worldToLocalRotationY() {
    Bone? parent = this.parent;
    if (parent == null) return arotation;
    double pa = parent.a;
    double pb = parent.b;
    double pc = parent.c;
    double pd = parent.d;
    return _toDeg(math.atan2(pa * d - pc * b, pd * b - pb * d));
  }

  void rotateWorld(double degrees) {
    double a = this.a;
    double b = this.b;
    double c = this.c;
    double d = this.d;
    double cos = _cosDeg(degrees);
    double sin = _sinDeg(degrees);
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

  void _updateAppliedTransform() {
    this.appliedValid = true;
    Bone? parent = this.parent;

    if (parent == null) {
      ax = worldX;
      ay = worldY;
      arotation = _toDeg(math.atan2(c, a));
      ascaleX = math.sqrt(a * a + c * c);
      ascaleY = math.sqrt(b * b + d * d);
      ashearX = 0.0;
      ashearY = _toDeg(math.atan2(a * b + c * d, a * d - b * c));
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

    if (this.ascaleX > 0.0001) {
      double det = ra * rd - rb * rc;
      this.ascaleY = det / this.ascaleX;
      this.ashearY = _toDeg(math.atan2(ra * rb + rc * rd, det));
      this.arotation = _toDeg(math.atan2(rc, ra));
    } else {
      this.ascaleX = 0.0;
      this.ascaleY = math.sqrt(rb * rb + rd * rd);
      this.ashearY = 0.0;
      this.arotation = 90.0 - _toDeg(math.atan2(rd, rb));
    }
  }

  void worldToLocal(Float32List world) {
    double invDet = 1.0 / (a * d - b * c);
    double x = world[0] - worldX;
    double y = world[1] - worldY;
    world[0] = x * d * invDet - y * b * invDet;
    world[1] = y * a * invDet - x * c * invDet;
  }

  void localToWorld(Float32List local) {
    double localX = local[0];
    double localY = local[1];
    local[0] = localX * a + localY * b + worldX;
    local[1] = localX * c + localY * d + worldY;
  }

  @override
  String toString() => this.data.name;
}
