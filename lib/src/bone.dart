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
  num appliedRotation = 0.0;

  num _a = 1.0;
  num _b = 0.0;
  num _c = 0.0;
  num _d = 1.0;
  num _worldX = 0.0;
  num _worldY = 0.0;
  num _worldSignX = 0.0;
  num _worldSignY = 0.0;

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

  void updateWorldTransformWith(
      num x, num y, num rotation,
      num scaleX, num scaleY, num shearX, num shearY) {

    this.appliedRotation = rotation;

    num deg2rad = math.PI / 180.0;
    num rotationX = deg2rad * (rotation + shearX);
    num rotationY = deg2rad * (rotation + 90 + shearY);
    num la = math.cos(rotationX) * scaleX;
    num lb = math.cos(rotationY) * scaleY;
    num lc = math.sin(rotationX) * scaleX;
    num ld = math.sin(rotationY) * scaleY;

    if (parent == null) {
      _a = la;
      _b = lb;
      _c = lc;
      _d = ld;
      _worldX = x;
      _worldY = y;
      _worldSignX = scaleX < 0 ? -1 : 1;
      _worldSignY = scaleY < 0 ? -1 : 1;
      return;
    }

    num pa = parent.a;
    num pb = parent.b;
    num pc = parent.c;
    num pd = parent.d;

    _worldX = pa * x + pb * y + parent.worldX;
    _worldY = pc * x + pd * y + parent.worldY;
    _worldSignX = parent.worldSignX * (scaleX < 0 ? -1 : 1);
    _worldSignY = parent.worldSignY * (scaleY < 0 ? -1 : 1);

    if (data.inheritRotation && data.inheritScale) {

      _a = pa * la + pb * lc;
      _b = pa * lb + pb * ld;
      _c = pc * la + pd * lc;
      _d = pc * lb + pd * ld;

    } else if (data.inheritRotation) { // No scale inheritance.

      pa = 1;
      pb = 0;
      pc = 0;
      pd = 1;

      for (var p = parent; p != null; p = p.parent) {

        num cos = math.cos(deg2rad * p.appliedRotation);
        num sin = math.sin(deg2rad * p.appliedRotation);
        num temp = pa * cos + pb * sin;
        pb = pb * cos - pa * sin;
        pa = temp;
        temp = pc * cos + pd * sin;
        pd = pd * cos - pc * sin;
        pc = temp;

        if (p.data.inheritRotation == false) break;
      }

      _a = pa * la + pb * lc;
      _b = pa * lb + pb * ld;
      _c = pc * la + pd * lc;
      _d = pc * lb + pd * ld;

    } else if (data.inheritScale) { // No rotation inheritance.

      pa = 1;
      pb = 0;
      pc = 0;
      pd = 1;

      for (var p = parent; p != null; p = p.parent) {

        num cos = math.cos(deg2rad * p.appliedRotation);
        num sin = math.sin(deg2rad * p.appliedRotation);
        num psx = p.scaleX;
        num psy = p.scaleY;
        num za = cos * psx;
        num zb = sin * psy;
        num zc = sin * psx;
        num zd = cos * psy;
        num temp = pa * za + pb * zc;
        pb = pb * zd - pa * zb;
        pa = temp;
        temp = pc * za + pd * zc;
        pd = pd * zd - pc * zb;
        pc = temp;

        if (psx >= 0) sin = -sin;
        temp = pa * cos + pb * sin;
        pb = pb * cos - pa * sin;
        pa = temp;
        temp = pc * cos + pd * sin;
        pd = pd * cos - pc * sin;
        pc = temp;

        if (p.data.inheritScale == false) break;
      }

      _a = pa * la + pb * lc;
      _b = pa * lb + pb * ld;
      _c = pc * la + pd * lc;
      _d = pc * lb + pd * ld;

    } else {

      _a = la;
      _b = lb;
      _c = lc;
      _d = ld;
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

  num get worldSignX => _worldSignX;
  num get worldSignY => _worldSignY;
  num get worldRotationX => math.atan2(_c, _a) * 180 / math.PI;
  num get worldRotationY => math.atan2(_d, _b) * 180 / math.PI;
  num get worldScaleX => math.sqrt(_a * _a + _b * _b) * _worldSignX;
  num get worldScaleY => math.sqrt(_c * _c + _d * _d) * _worldSignY;

  num worldToLocalRotationX() {
    Bone parent = this.parent;
    if (parent == null) return rotation;
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
    if (parent == null) return rotation;
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
  }

  /// Computes the local transform from the world transform. 
  /// This can be useful to perform processing on the local transform
  /// after the world transform has been modified directly (eg, by a constraint).
  ///
  /// Some redundant information is lost by the world transform, such as -1,-1 scale 
  /// versus 180 rotation. The computed local transform values may differ from the 
  /// original values but are functionally the same.
  
  void updateLocalTransform() {

    Bone parent = this.parent;
    num rad2deg = 180 / math.PI;

    if (parent == null) {
      x = worldX;
      y = worldY;
      rotation = math.atan2(c, a) * rad2deg;
      scaleX = math.sqrt(a * a + c * c);
      scaleY = math.sqrt(b * b + d * d);
      num det = a * d - b * c;
      shearX = 0;
      shearY = math.atan2(a * b + c * d, det) * rad2deg;
      return;
    }

    num pa = parent.a;
    num	pb = parent.b;
    num pc = parent.c;
    num pd = parent.d;
    num pid = 1.0 / (pa * pd - pb * pc);
    num dx = worldX - parent.worldX;
    num dy = worldY - parent.worldY;
    x = (dx * pd * pid - dy * pb * pid);
    y = (dy * pa * pid - dx * pc * pid);
    num ia = pid * pd;
    num id = pid * pa;
    num ib = pid * pb;
    num ic = pid * pc;
    num ra = ia * a - ib * c;
    num rb = ia * b - ib * d;
    num rc = id * c - ic * a;
    num rd = id * d - ic * b;
    shearX = 0;
    scaleX = math.sqrt(ra * ra + rc * rc);
    if (scaleX > 0.0001) {
      num det = ra * rd - rb * rc;
      scaleY = det / scaleX;
      shearY = math.atan2(ra * rb + rc * rd, det) * rad2deg;
      rotation = math.atan2(rc, ra) * rad2deg;
    } else {
      scaleX = 0.0;
      scaleY = math.sqrt(rb * rb + rd * rd);
      shearY = 0.0;
      rotation = 90.0 - math.atan2(rd, rb) * rad2deg;
    }
    appliedRotation = rotation;
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
