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

  num x = 0.0;
  num y = 0.0;
  num rotation = 0.0;
  num scaleX = 0.0;
  num scaleY = 0.0;
  num shearX = 0.0;
  num shearY = 0.0;

  num ax = 0.0;
  num ay = 0.0;
  num arotation = 0.0;
  num ascaleX = 0.0;
  num ascaleY = 0.0;
  num ashearX = 0.0;
  num ashearY = 0.0;
  bool appliedValid = false;

  num _a = 1.0;
  num _b = 0.0;
  num _c = 0.0;
  num _d = 1.0;
  num _worldX = 0.0;
  num _worldY = 0.0;

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
      num x, num y, num rotation,
      num scaleX, num scaleY, num shearX, num shearY) {

    ax = x;
		ay = y;
		arotation = rotation;
		ascaleX = scaleX;
		ascaleY = scaleY;
		ashearX = shearX;
		ashearY = shearY;
		appliedValid = true;

    num deg2rad = math.PI / 180.0;
    num rad2deg = 180.0 / math.PI;
		num rotationY = 0.0, la = 0.0, lb = 0.0, lc = 0.0, ld = 0.0;
		num sin = 0.0, cos = 0.0;
		num s = 0.0;
		
		Bone parent = this.parent;
		if (parent == null) { // Root bone.
			rotationY = rotation + 90 + shearY;
			la = math.cos(deg2rad * (rotation + shearX)) * scaleX;
			lb = math.cos(deg2rad * rotationY) * scaleY;
			lc = math.sin(deg2rad * (rotation + shearX)) * scaleX;
			ld = math.sin(deg2rad * rotationY) * scaleY;
      Skeleton  skeleton = this.skeleton;
			_a = la;
			_b = lb;
			_c = lc;
			_d = ld;
			_worldX = x + skeleton.x;
			_worldY = y + skeleton.y;	
			return;
		}

  num pa = parent._a;
  num pb = parent._b;
  num pc = parent._c;
  num pd = parent._d;

  _worldX = pa * x + pb * y + parent._worldX;
  _worldY = pc * x + pd * y + parent._worldY;

  switch (this.data.transformMode) {

    case TransformMode.normal:
      rotationY = rotation + 90 + shearY;
      la = math.cos(deg2rad * (rotation + shearX)) * scaleX;
      lb = math.cos(deg2rad * rotationY) * scaleY;
      lc = math.sin(deg2rad * (rotation + shearX)) * scaleX;
      ld = math.sin(deg2rad * rotationY) * scaleY;
      _a = pa * la + pb * lc;
      _b = pa * lb + pb * ld;
      _c = pc * la + pd * lc;
      _d = pc * lb + pd * ld;
      return;

    case TransformMode.onlyTranslation:
      rotationY = rotation + 90 + shearY;
      _a = math.cos(deg2rad * (rotation + shearX)) * scaleX;
      _b = math.cos(deg2rad * rotationY) * scaleY;
      _c = math.sin(deg2rad * (rotation + shearX)) * scaleX;
      _d = math.sin(deg2rad * rotationY) * scaleY;
      break;

    case TransformMode.noRotationOrReflection:
      s = pa * pa + pc * pc;
      num prx = 0.0;
      if (s > 0.0001) {
        s = (pa * pd - pb * pc).abs() / s;
        pb = pc * s;
        pd = pa * s;
        prx = math.atan2(pc, pa) * rad2deg;
      } else {
        pa = 0;
        pc = 0;
        prx = 90 - math.atan2(pd, pb) * rad2deg;
      }
      num rx = rotation + shearX - prx;
      num ry = rotation + shearY - prx + 90;
      la = math.cos(deg2rad * rx) * scaleX;
      lb = math.cos(deg2rad * ry) * scaleY;
      lc = math.sin(deg2rad * rx) * scaleX;
      ld = math.sin(deg2rad * ry) * scaleY;
      _a = pa * la - pb * lc;
      _b = pa * lb - pb * ld;
      _c = pc * la + pd * lc;
      _d = pc * lb + pd * ld;
      break;

    case TransformMode.noScale:
    case TransformMode.noScaleOrReflection:
      cos = math.cos(deg2rad * rotation);
      sin = math.sin(deg2rad * rotation);
      num za = pa * cos + pb * sin;
      num zc = pc * cos + pd * sin;
      s = math.sqrt(za * za + zc * zc);
      if (s > 0.00001) s = 1 / s;
      za *= s;
      zc *= s;
      s = math.sqrt(za * za + zc * zc);
      num r = math.PI / 2 + math.atan2(zc, za);
      num zb = math.cos(r) * s;
      num zd = math.sin(r) * s;
      la = math.cos(deg2rad * shearX) * scaleX;
      lb = math.cos(deg2rad * (90 + shearY)) * scaleY;
      lc = math.sin(deg2rad * shearX) * scaleX;
      ld = math.sin(deg2rad * (90 + shearY)) * scaleY;
      _a = za * la + zb * lc;
      _b = za * lb + zb * ld;
      _c = zc * la + zd * lc;
      _d = zc * lb + zd * ld;

      if (this.data.transformMode != TransformMode.noScaleOrReflection ? pa * pd - pb * pc < 0 : false) {
        _b = -_b;
        _d = -_d;
      }

      return;
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

  num get a => _a;
  num get b => _b;
  num get c => _c;
  num get d => _d;
  num get worldX => _worldX;
  num get worldY => _worldY;

  num get worldRotationX => math.atan2(_c, _a) * 180 / math.PI;
  num get worldRotationY => math.atan2(_d, _b) * 180 / math.PI;
  num get worldScaleX => math.sqrt(_a * _a + _c * _c);
  num get worldScaleY => math.sqrt(_b * _b + _d * _d);

  num worldToLocalRotationX() {
    Bone parent = this.parent;
    if (parent == null) return arotation;
    num pa = parent.a;
    num pb = parent.b;
    num pc = parent.c;
    num pd = parent.d;
    num a = this.a;
    num c = this.c;
    num rad2deg = 180 / math.PI;
    return math.atan2(pa * c - pc * a, pd * a - pb * c) * rad2deg;
  }

  num worldToLocalRotationY() {
    Bone parent = this.parent;
    if (parent == null) return arotation;
    num pa = parent.a;
    num pb = parent.b;
    num pc = parent.c;
    num pd = parent.d;
    num b = this.b;
    num d = this.d;
    num rad2deg = 180 / math.PI;
    return math.atan2(pa * d - pc * b, pd * b - pb * d) * rad2deg;
  }

  void rotateWorld (num degrees) {
    num a = this.a;
    num b = this.b;
    num c = this.c;
	  num d = this.d;
	  num deg2rad = math.PI / 180.0;
    num cos = math.cos(deg2rad * degrees);
	  num	sin = math.sin(deg2rad * degrees);
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
    num rad2deg = 180.0 / math.PI;

    if (parent == null) {
      this.ax = worldX;
      this.ay = worldY;
      this.arotation = math.atan2(c, a) * rad2deg;
      this.ascaleX = math.sqrt(a * a + c * c);
      this.ascaleY = math.sqrt(b * b + d * d);
      this.ashearX = 0.0;
      this.ashearY = math.atan2(a * b + c * d, a * d - b * c) * rad2deg;
			return;
		}

		num pa = parent.a;
    num pb = parent.b;
    num pc = parent.c;
    num pd = parent.d;
		num pid = 1.0 / (pa * pd - pb * pc);

    num dx = worldX - parent.worldX;
    num dy = worldY - parent.worldY;
    this.ax = (dx * pd * pid - dy * pb * pid);
    this.ay = (dy * pa * pid - dx * pc * pid);
		num ia = pid * pd;
		num id = pid * pa;
		num ib = pid * pb;
		num ic = pid * pc;
		num ra = ia * a - ib * c;
		num rb = ia * b - ib * d;
		num rc = id * c - ic * a;
		num rd = id * d - ic * b;
		this.ashearX = 0;
    this.ascaleX = math.sqrt(ra * ra + rc * rc);
		if (this.scaleX > 0.0001) {
			num det = ra * rd - rb * rc;
			this.ascaleY = det /ascaleX;
      this.ashearY = math.atan2(ra * rb + rc * rd, det) * rad2deg;
      this.arotation = math.atan2(rc, ra) * rad2deg;
		} else {
			this.ascaleX = 0.0;
      this.ascaleY = math.sqrt(rb * rb + rd * rd);
      this.ashearY = 0.0;
      this.arotation = 90.0 - math.atan2(rd, rb) * rad2deg;
		}
	}
	
  void worldToLocal (Float32List world) {
    num a = _a;
    num b = _b;
    num c = _c;
    num d = _d;
    num x = world[0] - _worldX;
    num y = world[1] - _worldY;
    world[0] = (x * d - y * b) / (a * d - b * c);
    world[1] = (y * a - x * c) / (a * d - b * c);
  }

  void localToWorld (Float32List local) {
    num localX = local[0];
    num localY = local[1];
    local[0] = localX * _a + localY * _b + _worldX;
    local[1] = localX * _c + localY * _d + _worldY;
  }

  String toString() => this.data.name;
}
