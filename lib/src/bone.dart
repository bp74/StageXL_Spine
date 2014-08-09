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

  static bool yDown;

  BoneData _data; // internal
  Bone _parent; // internal
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

  Bone(BoneData data, Bone parent) {
    if (data == null) throw new ArgumentError("data cannot be null.");
    _data = data;
    _parent = parent;
    setToSetupPose();
  }

  /** Computes the world SRT using the parent bone and the local SRT. */
  void updateWorldTransform(bool flipX, bool flipY) {
    if (_parent != null) {
      _worldX = x * _parent._m00 + y * _parent._m01 + _parent._worldX;
      _worldY = x * _parent._m10 + y * _parent._m11 + _parent._worldY;
      if (_data.inheritScale) {
        _worldScaleX = _parent._worldScaleX * scaleX;
        _worldScaleY = _parent._worldScaleY * scaleY;
      } else {
        _worldScaleX = scaleX;
        _worldScaleY = scaleY;
      }
      _worldRotation = _data.inheritRotation ? _parent._worldRotation + rotation : rotation;
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
    x = _data.x;
    y = _data.y;
    rotation = _data.rotation;
    scaleX = _data.scaleX;
    scaleY = _data.scaleY;
  }

  BoneData get data => _data;
  Bone get parent => _parent;

  num get m00 => _m00;
  num get m01 => _m01;
  num get m10 => _m10;
  num get m11 => _m11;
  num get worldX => _worldX;
  num get worldY => _worldY;
  num get worldRotation => _worldRotation;
  num get worldScaleX => _worldScaleX;
  num get worldScaleY => _worldScaleY;

  String toString() => _data.name;
}
