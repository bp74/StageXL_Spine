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

class IkConstraint implements Updatable {

  final List<Bone> bones = new List<Bone>();
  final IkConstraintData data;
  Bone target = null;

  num mix = 1.0;
  int bendDirection = 0;
  int level = 0;

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

  void update() {
    switch (bones.length) {
      case 1:
        apply1(bones[0], target.worldX, target.worldY, mix);
        break;
      case 2:
        apply2(bones[0], bones[1], target.worldX, target.worldY, bendDirection,
            mix);
        break;
    }
  }

  String toString() => data.name;

  /// Adjusts the bone rotation so the tip is as close to the target
  /// position as possible. The target is specified in the world
  /// coordinate system.

  static void apply1(Bone bone, num targetX, num targetY, num alpha) {

    Bone pp = bone.parent;
    num rad2deg = 180 / math.PI;
    num id = 1.0 / (pp.a * pp.d - pp.b * pp.c);
    num x = targetX - pp.worldX;
    num y = targetY - pp.worldY;
    num tx = (x * pp.d - y * pp.b) * id - bone.x;
    num ty = (y * pp.a - x * pp.c) * id - bone.y;

    num rotationIK = math.atan2(ty, tx) * rad2deg - bone.shearX - bone.rotation;
    if (bone.scaleX < 0) rotationIK += 180;
    if (rotationIK > 180) {
      rotationIK -= 360;
    } else if (rotationIK < -180) {
      rotationIK += 360;
    }

    bone.updateWorldTransformWith(
        bone.x, bone.y,
        bone.rotation + rotationIK * alpha,
        bone.scaleX, bone.scaleY,
        bone.shearX, bone.shearY);
  }

  /// Adjusts the parent and child bone rotations so the tip of the
  /// child is as close to the target position as possible. The target
  /// is specified in the world coordinate system.
  ///
  /// [child] Any descendant bone of the parent.

  static void apply2(Bone parent, Bone child, num targetX, num targetY, int bendDir, num alpha) {

    if (alpha == 0) {
      child.updateWorldTransform();
      return;
    }

    num px = parent.x;
    num py = parent.y;
    num psx = parent.scaleX;
    num psy = parent.scaleY;
    num csx = child.scaleX;
    num rad2deg = 180 / math.PI;
    int os1 = 0, os2 = 0, s2 = 0;

    if (psx < 0) {
      psx = -psx; os1 = 180; s2 = -1;
    } else {
      os1 = 0; s2 = 1;
    }

    if (psy < 0) {
      psy = -psy; s2 = -s2;
    }

    if (csx < 0) {
      csx = -csx; os2 = 180;
    } else {
      os2 = 0;
    }

    num cx = child.x;
    num cy = 0.0;
    num cwx = 0.0;
    num cwy = 0.0;
    num a = parent.a;
    num b = parent.b;
    num c = parent.c;
    num d = parent.d;

    bool u = (psx - psy).abs() <= 0.0001;
    if (!u) {
      cy = 0;
      cwx = a * cx + parent.worldX;
      cwy = c * cx + parent.worldY;
    } else {
      cy = child.y;
      cwx = a * cx + b * cy + parent.worldX;
      cwy = c * cx + d * cy + parent.worldY;
    }

    Bone pp = parent.parent;
    a = pp.a;
    b = pp.b;
    c = pp.c;
    d = pp.d;
    num id = 1.0 / (a * d - b * c);
    num x = targetX - pp.worldX;
    num y = targetY - pp.worldY;
    num tx = (x * d - y * b) * id - px;
    num ty = (y * a - x * c) * id - py;
    x = cwx - pp.worldX;
    y = cwy - pp.worldY;
    num dx = (x * d - y * b) * id - px;
    num dy = (y * a - x * c) * id - py;
    num l1 = math.sqrt(dx * dx + dy * dy);
    num l2 = child.data.length * csx;
    num a1 = 0.0;
    num a2 = 0.0;

    outer: if (u) {
      l2 *= psx;
      num cos = (tx * tx + ty * ty - l1 * l1 - l2 * l2) / (2 * l1 * l2);
      if (cos < -1) cos = -1; else if (cos > 1) cos = 1;
      a2 = math.acos(cos) * bendDir;
      a = l1 + l2 * cos;
      b = l2 * math.sin(a2);
      a1 = math.atan2(ty * a - tx * b, tx * a + ty * b);
    } else {
      a = psx * l2;
      b = psy * l2;
      num aa = a * a;
      num bb = b * b;
      num dd = tx * tx + ty * ty;
      num ta = math.atan2(ty, tx);
      c = bb * l1 * l1 + aa * dd - aa * bb;
      num c1 = -2 * bb * l1;
      num c2 = bb - aa;
      d = c1 * c1 - 4 * c2 * c;
      if (d >= 0) {
        num q = math.sqrt(d);
        if (c1 < 0) q = -q;
        q = -(c1 + q) / 2;
        num r0 = q / c2;
        num r1 = c / q;
        num r = r0.abs() < r1.abs() ? r0 : r1;
        if (r * r <= dd) {
          y = math.sqrt(dd - r * r) * bendDir;
          a1 = ta - math.atan2(y, r);
          a2 = math.atan2(y / psy, (r - l1) / psx);
          break outer;
        }
      }

      num minAngle = 0.0;
      num minDist = double.MAX_FINITE;
      num minX = 0.0;
      num minY = 0.0;
      num maxAngle = 0.0;
      num maxDist = 0.0;
      num maxX = 0.0;
      num maxY = 0.0;
      x = l1 + a;
      d = x * x;
      if (d > maxDist) {
        maxAngle = 0;
        maxDist = d;
        maxX = x;
      }
      x = l1 - a;
      d = x * x;
      if (d < minDist) {
        minAngle = math.PI;
        minDist = d;
        minX = x;
      }
      num angle = math.acos(-a * l1 / (aa - bb));
      x = a * math.cos(angle) + l1;
      y = b * math.sin(angle);
      d = x * x + y * y;
      if (d < minDist) {
        minAngle = angle;
        minDist = d;
        minX = x;
        minY = y;
      }
      if (d > maxDist) {
        maxAngle = angle;
        maxDist = d;
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

    num os = math.atan2(cy, cx) * s2;
    num rotation = parent.rotation;
    a1 = (a1 - os) * rad2deg + os1 - rotation;
    if (a1 > 180) a1 -= 360; else if (a1 < -180) a1 += 360;
    parent.updateWorldTransformWith(px, py, rotation + a1 * alpha, parent.scaleX, parent.scaleY, 0, 0);
    rotation = child.rotation;
    a2 = ((a2 + os) * rad2deg - child.shearX) * s2 + os2 - rotation;
    if (a2 > 180) a2 -= 360; else if (a2 < -180) a2 += 360;
    child.updateWorldTransformWith(cx, cy, rotation + a2 * alpha, child.scaleX, child.scaleY, child.shearX, child.shearY);
  }
}
