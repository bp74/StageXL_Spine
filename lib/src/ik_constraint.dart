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

class IkConstraint implements Updatable {

  final List<Bone> bones = new List<Bone>();
  final IkConstraintData data;

  Bone target = null;
  int bendDirection = 0;
  num mix = 1.0;

  IkConstraint(this.data, Skeleton skeleton) {

    if (data == null) throw new ArgumentError("data cannot be null.");
    if (skeleton == null) throw new ArgumentError("skeleton cannot be null.");

    mix = data.mix;
    bendDirection = data.bendDirection;

    for (BoneData boneData in data.bones) {
      bones.add(skeleton.findBone(boneData.name));
    }

    target = skeleton.findBone(data.target.name);
  }

  void apply() {
    update();
  }

  void update () {
    switch (bones.length) {
      case 1:
        apply1(bones[0], target.worldX, target.worldY, mix);
        break;
      case 2:
        apply2(bones[0], bones[1], target.worldX, target.worldY, bendDirection, mix);
        break;
    }
  }

  String toString() => data.name;

  /// Adjusts the bone rotation so the tip is as close to the target
  /// position as possible. The target is specified in the world
  /// coordinate system.

  static void apply1(Bone bone, num targetX, num targetY, num alpha) {
    num parentRotation = bone.parent == null ? 0 : bone.parent.worldRotationX;
    num rad2deg = 180 / math.PI;
    num rotation = bone.rotation;
    num rotationIK = math.atan2(targetY - bone.worldY, targetX - bone.worldX) * rad2deg - parentRotation;
    if (bone.worldSignX != bone.worldSignY) rotationIK = 360 - rotationIK;
    if (rotationIK > 180) rotationIK -= 360; else if (rotationIK < -180) rotationIK += 360;
    bone.updateWorldTransformWith(bone.x, bone.y, rotation + (rotationIK - rotation) * alpha, bone.scaleX, bone.scaleY);
  }

  /// Adjusts the parent and child bone rotations so the tip of the
  /// child is as close to the target position as possible. The target
  /// is specified in the world coordinate system.
  ///
  /// [child] Any descendant bone of the parent.

  static void apply2(Bone parent, Bone child, num targetX, num targetY, int bendDir, num alpha) {

    if (alpha == 0) return;

    num px = parent.x;
    num py = parent.y;
    num psx = parent.scaleX;
    num psy = parent.scaleY;
    num csx = child.scaleX;
    num cy = child.y;

    int offset1 = 0;
    int offset2 = 0;
    int sign2 = 0;

    if (psx < 0) {
      psx = -psx;
      offset1 = 180;
      sign2 = -1;
    } else {
      offset1 = 0;
      sign2 = 1;
    }

    if (psy < 0) {
      psy = -psy;
      sign2 = -sign2;
    }

    if (csx < 0) {
      csx = -csx;
      offset2 = 180;
    } else {
      offset2 = 0;
    }

    Bone pp = parent.parent;
    num tx = 0.0;
    num ty = 0.0;
    num dx = 0.0;
    num dy = 0.0;

    if (pp == null) {

      tx = targetX - px;
      ty = targetY - py;
      dx = child.worldX - px;
      dy = child.worldY - py;

    } else {

      num ppa = pp.a;
      num ppb = pp.b;
      num ppc = pp.c;
      num ppd = pp.d;

      num invDet = 1 / (ppa * ppd - ppb * ppc);
      num wx = pp.worldX;
      num wy = pp.worldY;
      num twx = targetX - wx;
      num twy = targetY - wy;
      tx = (twx * ppd - twy * ppb) * invDet - px;
      ty = (twy * ppa - twx * ppc) * invDet - py;
      twx = child.worldX - wx;
      twy = child.worldY - wy;
      dx = (twx * ppd - twy * ppb) * invDet - px;
      dy = (twy * ppa - twx * ppc) * invDet - py;
    }

    num l1 = math.sqrt(dx * dx + dy * dy);
    num l2 = child.data.length * csx;
    num a1 = 0.0;
    num a2 = 0.0;

    outer:

    if ((psx - psy).abs() <= 0.0001) {

      l2 = l2 * psx;
      num cos = (tx * tx + ty * ty - l1 * l1 - l2 * l2) / (2 * l1 * l2);
      if (cos < -1) cos = -1; else if (cos > 1) cos = 1;
      a2 = math.acos(cos) * bendDir;
      num ad = l1 + l2 * cos;
      num o = l2 * math.sin(a2);
      a1 = math.atan2(ty * ad - tx * o, tx * ad + ty * o);

    } else {

      cy = 0;
      num a = psx * l2;
      num b = psy * l2;
      num ta = math.atan2(ty, tx);
      num aa = a * a;
      num bb = b * b;
      num ll = l1 * l1;
      num dd = tx * tx + ty * ty;
      num c0 = bb * ll + aa * dd - aa * bb;
      num c1 = -2 * bb * l1;
      num c2 = bb - aa;
      num d = c1 * c1 - 4 * c2 * c0;

      if (d >= 0) {
        num q = math.sqrt(d);
        if (c1 < 0) q = -q;
        q = -(c1 + q) / 2;
        num r0 = q / c2;
        num r1 = c0 / q;
        num r = r0.abs() < r1.abs() ? r0 : r1;
        if (r * r <= dd) {
          num y1 = math.sqrt(dd - r * r) * bendDir;
          a1 = ta - math.atan2(y1, r);
          a2 = math.atan2(y1 / psy, (r - l1) / psx);
          break outer;
        }
      }

      num minAngle = 0.0;
      num minDist = double.MAX_FINITE;
      num minX = 0.0;
      num minY = 0.0;
      num maxAngle = 0;
      num maxDist = 0;
      num maxX = 0;
      num maxY= 0;
      num x = l1 + a;
      num dist = x * x;
      if (dist > maxDist) {
        maxAngle = 0;
        maxDist = dist;
        maxX = x;
      }
      x = l1 - a;
      dist = x * x;
      if (dist < minDist) {
        minAngle = math.PI;
        minDist = dist;
        minX = x;
      }
      num angle = math.acos(-a * l1 / (aa - bb));
      x = a * math.cos(angle) + l1;
      num y = b * math.sin(angle);
      dist = x * x + y * y;
      if (dist < minDist) {
        minAngle = angle;
        minDist = dist;
        minX = x;
        minY = y;
      }
      if (dist > maxDist) {
        maxAngle = angle;
        maxDist = dist;
        maxX = x;
        maxY = y;
      }
      if (dd <= (minDist + maxDist) / 2) {
        a1 = ta - math.atan2(minY * bendDir, minX);
        a2 = minAngle * bendDir;
      } else {
        a1 = ta - math.atan2(maxY * bendDir, maxX);
        a2 = maxAngle * bendDir;
      }
    }

    num offset = math.atan2(cy, child.x) * sign2;
    a1 = (a1 - offset) * 180.0 / math.PI + offset1;
    a2 = (a2 + offset) * 180.0 / math.PI * sign2 + offset2;
    if (a1 > 180) a1 -= 360; else if (a1 < -180) a1 += 360;
    if (a2 > 180) a2 -= 360; else if (a2 < -180) a2 += 360;
    num rotation = parent.rotation;
    parent.updateWorldTransformWith(parent.x, parent.y, rotation + (a1 - rotation) * alpha, parent.scaleX, parent.scaleY);
    rotation = child.rotation;
    child.updateWorldTransformWith(child.x, cy, rotation + (a2 - rotation) * alpha, child.scaleX, child.scaleY);
  }
}
