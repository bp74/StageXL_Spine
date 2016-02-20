/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.1
 *
 * Copyright (c) 2013, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to install, execute and perform the Spine Runtimes
 * Software (the "Software") solely for internal use. Without the written
 * permission of Esoteric Software (typically granted by licensing Spine), you
 * may not (a) modify, translate, adapt or otherwise create derivative works,
 * improvements of the Software or develop new applications using the Software
 * or (b) remove, delete, alter or obscure any trademarks or any copyright,
 * trademark, patent or other intellectual property or proprietary rights
 * notices on or in the Software, including any copy thereof. Redistributions
 * in binary or source form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;

class Bone implements Updatable {

  final BoneData data;
  final Skeleton skeleton;
  final Bone parent;

  num x = 0.0;
  num y = 0.0;
  num scaleX = 0.0;
  num scaleY = 0.0;
  num rotation = 0.0;
  num appliedScaleX = 0.0;
  num appliedScaleY = 0.0;
  num appliedRotation = 0.0;

  num _a = 1.0;
  num _b = 0.0;
  num _c = 0.0;
  num _d = 1.0;

  num _worldX = 0.0;
  num _worldY = 0.0;
  num _worldSignX = 0.0;
  num _worldSignY = 0.0;

  Bone(this.data, this.skeleton, this.parent) {
    if (data == null) throw new ArgumentError("data cannot be null.");
    if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");
    setToSetupPose();
  }

  /// Computes the world SRT using the parent bone and this bone's local SRT.

  void updateWorldTransform() {
    updateWorldTransformWith(x, y, rotation, scaleX, scaleY);
  }

  /// Same as updateWorldTransform(). This method exists for Bone to implement
  /// Updatable.

  void update () {
    updateWorldTransformWith(x, y, rotation, scaleX, scaleY);
  }

  /// Computes the world SRT using the parent bone and the specified local SRT.
  void updateWorldTransformWith(num x, num y, num rotation, num scaleX, num scaleY) {

    this.appliedRotation = rotation;
    this.appliedScaleX = scaleX;
    this.appliedScaleY = scaleY;

    num radians = rotation * math.PI / 180.0;
    num cos = math.cos(radians);
    num sin = math.sin(radians);
    num la = cos * scaleX;
    num lb = -sin * scaleY;
    num lc = sin * scaleX;
    num ld = cos * scaleY;

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

    num pa = parent._a;
    num pb = parent._b;
    num pc = parent._c;
    num pd = parent._d;

    _worldX = pa * x + pb * y + parent._worldX;
    _worldY = pc * x + pd * y + parent._worldY;
    _worldSignX = parent._worldSignX * (scaleX < 0 ? -1 : 1);
    _worldSignY = parent._worldSignY * (scaleY < 0 ? -1 : 1);

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
        radians = p.appliedRotation * math.PI / 180.0;
        cos = math.cos(radians);
        sin = math.sin(radians);
        num temp = pa * cos + pb * sin;
        pb = pa * -sin + pb * cos;
        pa = temp;
        temp = pc * cos + pd * sin;
        pd = pc * -sin + pd * cos;
        pc = temp;
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

        radians = p.rotation * math.PI / 180.0;
        cos = math.cos(radians);
        sin = math.sin(radians);

        num psx = p.appliedScaleX;
        num psy = p.appliedScaleY;
        num za = cos * psx;
        num zb = -sin * psy;
        num zc = sin * psx;
        num zd = cos * psy;

        num temp = pa * za + pb * zc;
        pb = pa * zb + pb * zd;
        pa = temp;
        temp = pc * za + pd * zc;
        pd = pc * zb + pd * zd;
        pc = temp;

        if (psx < 0) radians = -radians;
        cos = math.cos(-radians);
        sin = math.sin(-radians);
        temp = pa * cos + pb * sin;
        pb = pa * -sin + pb * cos;
        pa = temp;
        temp = pc * cos + pd * sin;
        pd = pc * -sin + pd * cos;
        pc = temp;
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
    scaleX = this.data.scaleX;
    scaleY = this.data.scaleY;
    rotation = this.data.rotation;
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

  void worldToLocal (Float32List world) {
    num x = world[0] - _worldX;
    num y = world[1] - _worldY;
    num a = _a;
    num b = _b;
    num c = _c;
    num d = _d;
    num invDet = 1 / (a * d - b * c);
    world[0] = (x * a * invDet - y * b * invDet);
    world[1] = (y * d * invDet - x * c * invDet);
  }

  void localToWorld (Float32List local) {
    num localX = local[0];
    num localY = local[1];
    local[0] = localX * _a + localY * _b + _worldX;
    local[1] = localX * _c + localY * _d + _worldY;
  }

  String toString() => this.data.name;
}
