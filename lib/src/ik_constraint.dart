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

class IkConstraint {

  static final num _radDeg = 180 / math.PI;
  static final Float32List _tempPosition = new Float32List(2);

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
  ///
  static void apply1(Bone bone, num targetX, num targetY, num alpha) {
    num parentRotation = (!bone.data.inheritRotation || bone.parent == null) ? 0 : bone.parent.worldRotation;
    num rotation = bone.rotation;
    num rotationIK = math.atan2(targetY - bone.worldY, targetX - bone.worldX) * _radDeg - parentRotation;
    bone.rotationIK = rotation + (rotationIK - rotation) * alpha;
  }

  /// Adjusts the parent and child bone rotations so the tip of the
  /// child is as close to the target position as possible. The target
  /// is specified in the world coordinate system.
  ///
  /// [child] Any descendant bone of the parent.
  ///
  static void apply2(Bone parent, Bone child, num targetX, num targetY, int bendDirection, num alpha) {

    num childRotation = child.rotation;
    num parentRotation = parent.rotation;

    if (alpha == 0) {
      child.rotationIK = childRotation;
      parent.rotationIK = parentRotation;
      return;
    }

    num positionX = 0.0;
    num positionY = 0.0;
    Bone parentParent = parent.parent;

    if (parentParent != null) {
      _tempPosition[0] = targetX;
      _tempPosition[1] = targetY;
      parentParent.worldToLocal(_tempPosition);
      targetX = (_tempPosition[0] - parent.x) * parentParent.worldScaleX;
      targetY = (_tempPosition[1] - parent.y) * parentParent.worldScaleY;
    } else {
      targetX -= parent.x;
      targetY -= parent.y;
    }

    if (child.parent == parent) {
      positionX = child.x;
      positionY = child.y;
    } else {
      _tempPosition[0] = child.x;
      _tempPosition[1] = child.y;
      child.parent.localToWorld(_tempPosition);
      parent.worldToLocal(_tempPosition);
      positionX = _tempPosition[0];
      positionY = _tempPosition[1];
    }

    num childX = positionX * parent.worldScaleX;
    num childY = positionY * parent.worldScaleY;
    num offset = math.atan2(childY, childX);
    num len1 = math.sqrt(childX * childX + childY * childY);
    num len2 = child.data.length * child.worldScaleX;

    // Based on code by Ryan Juckett with permission: Copyright (c) 2008-2009 Ryan Juckett
    // http://www.ryanjuckett.com/

    num cosDenom = 2.0 * len1 * len2;
    if (cosDenom < 0.0001) {
      child.rotationIK = childRotation + (math.atan2(targetY, targetX) * _radDeg - parentRotation - childRotation) * alpha;
      return;
    }

    num cos = (targetX * targetX + targetY * targetY - len1 * len1 - len2 * len2) / cosDenom;
    if (cos >  1.0) cos =  1.0;
    if (cos < -1.0) cos = -1.0;
    num childAngle = math.acos(cos) * bendDirection;
    num adjacent = len1 + len2 * cos;
    num opposite = len2 * math.sin(childAngle);
    num parentAngle = math.atan2(targetY * adjacent - targetX * opposite, targetX * adjacent + targetY * opposite);
    num rotation = (parentAngle - offset) * _radDeg - parentRotation;
    if (rotation >  180.0) rotation -= 360.0;
    if (rotation < -180.0) rotation += 360.0;
    parent.rotationIK = parentRotation + rotation * alpha;
    rotation = (childAngle + offset) * _radDeg - childRotation;
    if (rotation >  180.0) rotation -= 360.0;
    if (rotation < -180.0) rotation += 360.0;
    child.rotationIK = childRotation + (rotation + parent.worldRotation - child.parent.worldRotation) * alpha;
  }
}
