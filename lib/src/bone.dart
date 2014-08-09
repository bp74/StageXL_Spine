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

  static bool yDown = false;

  final BoneData data;
  final Bone parent;

  num x;
  num y;
  num rotation;
  num scaleX;
  num scaleY;

  num _m00; // internal
  num _m01; // internal
  num _m10; // internal
  num _m11; // internal
  num _worldX; // internal
  num _worldY; // internal
  num _worldRotation; // internal
  num _worldScaleX; // internal
  num _worldScaleY; // internal

  Bone(this.data, this.parent) {
    if (data == null) throw new ArgumentError("data cannot be null.");
    setToSetupPose();
  }

  /** Computes the world SRT using the parent bone and the local SRT. */
  void updateWorldTransform(bool flipX, bool flipY) {

    if (this.parent != null) {

      _worldX = x * this.parent._m00 + y * this.parent._m01 + this.parent._worldX;
      _worldY = x * this.parent._m10 + y * this.parent._m11 + this.parent._worldY;

      if (this.data.inheritScale) {
        _worldScaleX = parent._worldScaleX * scaleX;
        _worldScaleY = parent._worldScaleY * scaleY;
      } else {
        _worldScaleX = scaleX;
        _worldScaleY = scaleY;
      }

      _worldRotation = this.data.inheritRotation ? this.parent._worldRotation + rotation : rotation;

    } else {

      _worldX = flipX ? -x : x;
      _worldY = flipY != yDown ? -y : y;
      _worldScaleX = scaleX;
      _worldScaleY = scaleY;
      _worldRotation = rotation;
    }

    num radians = _worldRotation * (math.PI / 180);
    num cos = math.cos(radians);
    num sin = math.sin(radians);
    _m00 = cos * _worldScaleX;
    _m10 = sin * _worldScaleX;
    _m01 = -sin * _worldScaleY;
    _m11 = cos * _worldScaleY;

    if (flipX) {
      _m00 = -_m00;
      _m01 = -_m01;
    }
    if (flipY != yDown) {
      _m10 = -_m10;
      _m11 = -_m11;
    }
  }

  void setToSetupPose() {
    x = this.data.x;
    y = this.data.y;
    rotation = this.data.rotation;
    scaleX = this.data.scaleX;
    scaleY = this.data.scaleY;
  }

  num get m00 => _m00;
  num get m01 => _m01;
  num get m10 => _m10;
  num get m11 => _m11;
  num get worldX => _worldX;
  num get worldY => _worldY;
  num get worldRotation => _worldRotation;
  num get worldScaleX => _worldScaleX;
  num get worldScaleY => _worldScaleY;

  String toString() => this.data.name;
}
