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
  final Bone parent;
  final Matrix worldMatrix = new Matrix.fromIdentity();

  num x = 0.0;
  num y = 0.0;
  num rotation = 0.0;
  num scaleX = 0.0;
  num scaleY = 0.0;

  num _worldX = 0.0;
  num _worldY = 0.0;
  num _worldRotation = 0.0;
  num _worldScaleX = 0.0;
  num _worldScaleY = 0.0;

  Bone(this.data, this.parent) {
    if (data == null) throw new ArgumentError("data cannot be null.");
    setToSetupPose();
  }

  /// Computes the world SRT using the parent bone and the local SRT.
  ///
  void updateWorldTransform(bool flipX, bool flipY) {

    if (this.parent != null) {

      Matrix parentMatrix = parent.worldMatrix;

      _worldX = x * parentMatrix.a + y * parentMatrix.c + parentMatrix.tx;
      _worldY = x * parentMatrix.b + y * parentMatrix.d + parentMatrix.ty;
      _worldScaleX = data.inheritScale ? parent._worldScaleX * scaleX : scaleX;
      _worldScaleY = data.inheritScale ? parent._worldScaleY * scaleY : scaleY;
      _worldRotation = data.inheritRotation ? parent._worldRotation + rotation : rotation;

    } else {

      _worldX = flipX ? -x : x;
      _worldY = flipY ? y : -y;
      _worldScaleX = scaleX;
      _worldScaleY = scaleY;
      _worldRotation = rotation;
    }

    num radians = _worldRotation * math.PI / 180.0;
    num cos = math.cos(radians);
    num sin = math.sin(radians);

    num a =  cos * _worldScaleX;
    num b = -sin * _worldScaleX;
    num c = -sin * _worldScaleY;
    num d = -cos * _worldScaleY;

    if (flipX) { a = -a; c = -c; }
    if (flipY) { b = -b; d = -d; }

    this.worldMatrix.setTo(a, b, c, d, _worldX, _worldY);
  }

  void setToSetupPose() {
    x = this.data.x;
    y = this.data.y;
    rotation = this.data.rotation;
    scaleX = this.data.scaleX;
    scaleY = this.data.scaleY;
  }

  num get worldX => _worldX;
  num get worldY => _worldY;
  num get worldRotation => _worldRotation;
  num get worldScaleX => _worldScaleX;
  num get worldScaleY => _worldScaleY;

  String toString() => this.data.name;
}
