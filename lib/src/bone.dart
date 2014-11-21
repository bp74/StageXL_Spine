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

class Bone {

  final BoneData data;
  final Skeleton skeleton;
  final Bone parent;
  final Matrix worldMatrix = new Matrix.fromIdentity();

  num x = 0.0;
  num y = 0.0;
  num scaleX = 0.0;
  num scaleY = 0.0;
  num rotation = 0.0;
  num rotationIK = 0.0;
  bool flipX = false;
  bool flipY = false;

  num _worldX = 0.0;
  num _worldY = 0.0;
  num _worldScaleX = 0.0;
  num _worldScaleY = 0.0;
  num _worldRotation = 0.0;
  bool _worldFlipX = false;
  bool _worldFlipY = false;

  Bone(this.data, this.skeleton, this.parent) {
    if (data == null) throw new ArgumentError("data cannot be null.");
    if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");
    setToSetupPose();
  }

  /// Computes the world SRT using the parent bone and the local SRT.
  ///
  void updateWorldTransform() {

    if (this.parent != null) {

      Matrix parentMatrix = parent.worldMatrix;

      _worldX = x * parentMatrix.a + y * parentMatrix.c + parentMatrix.tx;
      _worldY = x * parentMatrix.b + y * parentMatrix.d + parentMatrix.ty;
      _worldScaleX = data.inheritScale ? parent._worldScaleX * scaleX : scaleX;
      _worldScaleY = data.inheritScale ? parent._worldScaleY * scaleY : scaleY;
      _worldRotation = data.inheritRotation ? parent._worldRotation + rotationIK : rotationIK;
      _worldFlipX = parent._worldFlipX != flipX;
      _worldFlipY = parent._worldFlipY != flipY;

    } else {

      var skeletonFlipX = skeleton.flipX;
      var skeletonFlipY = skeleton.flipY;

      _worldX = skeletonFlipX ? -x : x;
      _worldY = skeletonFlipY ? y : -y;
      _worldScaleX = scaleX;
      _worldScaleY = scaleY;
      _worldRotation = rotationIK;
      _worldFlipX = skeletonFlipX != flipX;
      _worldFlipY = skeletonFlipY != flipY;
    }

    num radians = _worldRotation * math.PI / 180.0;
    num cos = math.cos(radians);
    num sin = math.sin(radians);

    num a =  cos * _worldScaleX;
    num b = -sin * _worldScaleX;
    num c = -sin * _worldScaleY;
    num d = -cos * _worldScaleY;

    if (_worldFlipX) { a = -a; c = -c; }
    if (_worldFlipY) { b = -b; d = -d; }

    this.worldMatrix.setTo(a, b, c, d, _worldX, _worldY);
  }

  void setToSetupPose() {
    x = this.data.x;
    y = this.data.y;
    scaleX = this.data.scaleX;
    scaleY = this.data.scaleY;
    rotation = this.data.rotation;
    rotationIK = this.data.rotation;
    flipX = this.data.flipX;
    flipY = this.data.flipY;
  }

  num get worldX => _worldX;
  num get worldY => _worldY;
  num get worldScaleX => _worldScaleX;
  num get worldScaleY => _worldScaleY;
  num get worldRotation => _worldRotation;
  bool get worldFlipX => _worldFlipX;
  bool get worldFlipY => _worldFlipY;

  void worldToLocal (Float32List world) {

    num dx = world[0] - _worldX;
    num dy = world[1] - _worldY;
    num a = this.worldMatrix.a;
    num b = this.worldMatrix.b;
    num c = this.worldMatrix.c;
    num d = this.worldMatrix.d;

    if (_worldFlipX == _worldFlipY) {
      a = -a;
      d = -d;
    }

    num invDet = 1.0 / (a * d - c * b);
    world[0] = (dx * a * invDet - dy * c * invDet);
    world[1] = (dy * d * invDet - dx * b * invDet);
  }

  void localToWorld (Float32List local) {

    num localX = local[0];
    num localY = local[1];
    num a = this.worldMatrix.a;
    num b = this.worldMatrix.b;
    num c = this.worldMatrix.c;
    num d = this.worldMatrix.d;

    local[0] = localX * a + localY * c + _worldX;
    local[1] = localX * b + localY * d + _worldY;
  }

  String toString() => this.data.name;
}
