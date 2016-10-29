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

class TransformConstraint implements Updatable {

  final TransformConstraintData data;
  final List<Bone> bones = new List<Bone>();

  Bone target = null;
  num translateMix = 0.0;
  num rotateMix = 0.0;
  num scaleMix = 0.0;
  num shearMix = 0.0;

  final Float32List _temp = new Float32List(2);

  TransformConstraint (this.data, Skeleton skeleton) {

    if (data == null) throw new ArgumentError("data cannot be null.");
    if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");

    translateMix = data.translateMix;
    rotateMix = data.rotateMix;
    scaleMix = data.scaleMix;
    shearMix = data.shearMix;

    for (BoneData boneData in data.bones) {
      bones.add(skeleton.findBone(boneData.name));
    }

    target = skeleton.findBone(data.target.name);
  }

  void apply () {
    update();
  }

  void update () {

    num rotateMix = this.rotateMix;
    num translateMix = this.translateMix;
    num scaleMix = this.scaleMix;
    num shearMix = this.shearMix;
    num deg2rad = math.PI / 180.0;

    Bone target = this.target;

    num ta = target.a;
    num tb = target.b;
    num tc = target.c;
    num td = target.d;

    List<Bone> bones = this.bones;
    for (int i = 0; i < bones.length; i++) {
      var bone = bones[i];

      if (rotateMix > 0) {
        num a = bone.a;
        num b = bone.b;
        num c = bone.c;
        num d = bone.d;
        num r = math.atan2(tc, ta) - math.atan2(c, a) + data.offsetRotation * deg2rad;
        if (r > math.PI) r -= math.PI * 2; else if (r < -math.PI) r += math.PI * 2;
        r *= rotateMix;
        num cos = math.cos(r);
        num sin = math.sin(r);
        bone._a = cos * a - sin * c;
        bone._b = cos * b - sin * d;
        bone._c = sin * a + cos * c;
        bone._d = sin * b + cos * d;
      }

      if (translateMix > 0) {
        _temp[0] = data.offsetX;
        _temp[1] = data.offsetY;
        target.localToWorld(_temp);
        bone._worldX += (_temp[0] - bone.worldX) * translateMix;
        bone._worldY += (_temp[1] - bone.worldY) * translateMix;
      }

      if (scaleMix > 0) {
        num bs = math.sqrt(bone.a * bone.a + bone.c * bone.c);
        num ts = math.sqrt(ta * ta + tc * tc);
        num s = bs > 0.00001 ? (bs + (ts - bs + data.offsetScaleX) * scaleMix) / bs : 0;
        bone._a *= s;
        bone._c *= s;
        bs = math.sqrt(bone.b * bone.b + bone.d * bone.d);
        ts = math.sqrt(tb * tb + td * td);
        s = bs > 0.00001 ? (bs + (ts - bs + data.offsetScaleY) * scaleMix) / bs : 0;
        bone._b *= s;
        bone._d *= s;
      }

      if (shearMix > 0) {
        num b = bone.b;
        num d = bone.d;
        num by = math.atan2(d, b);
        num r = math.atan2(td, tb) - math.atan2(tc, ta) - (by - math.atan2(bone.c, bone.a));
        if (r > math.PI) r -= math.PI * 2; else if (r < -math.PI) r += math.PI * 2;
        r = by + (r + data.offsetShearY * deg2rad) * shearMix;
        num s = math.sqrt(b * b + d * d);
        bone._b = math.cos(r) * s;
        bone._d = math.sin(r) * s;
      }
    }
  }

  String toString () => data.name;

}
