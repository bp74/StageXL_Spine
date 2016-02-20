/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 *
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
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

        radians = p.appliedRotation * math.PI / 180.0;
        cos = math.cos(radians);
        sin = math.sin(radians);

        num ta = pa * cos + pb * sin;
        num tb = pb * cos - pa * sin;
        num tc = pc * cos + pd * sin;
        num td = pd * cos - pc * sin;

        pa = ta;
        pb = tb;
        pc = tc;
        pd = td;
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

        num ta = p.appliedScaleX * (pa * cos + pb * sin);
        num tb = p.appliedScaleY * (pb * cos - pa * sin);
        num tc = p.appliedScaleX * (pc * cos + pd * sin);
        num td = p.appliedScaleY * (pd * cos - pc * sin);

        if (p.appliedScaleX < 0) radians = -radians;
        cos = math.cos(-radians);
        sin = math.sin(-radians);

        pa = ta * cos + tb * sin;
        pb = tb * cos - ta * sin;
        pc = tc * cos + td * sin;
        pd = td * cos - tc * sin;
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
