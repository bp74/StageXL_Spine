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

class SkeletonData {
  String? name = "";
  String version = "";
  String hash = "";
  String imagesPath = "";
  double width = 0.0;
  double height = 0.0;
  double fps = 30.0;

  List<BoneData> bones = []; // Ordered parents first.
  List<SlotData> slots = []; // Setup pose draw order.
  List<Skin> skins = [];
  List<EventData> events = [];
  List<Animation> animations = [];
  List<IkConstraintData> ikConstraints = [];
  List<TransformConstraintData> transformConstraints = [];
  List<PathConstraintData> pathConstraints = [];

  Skin? defaultSkin;

  // --- Bones.

  BoneData? findBone(String boneName) {
    return bones.firstWhere((b) => b.name == boneName);
  }

  int findBoneIndex(String boneName) {
    for (int i = 0; i < bones.length; i++) {
      if (bones[i].name == boneName) return i;
    }
    return -1;
  }

  // --- Slots.

  SlotData? findSlot(String slotName) {
    return slots.firstWhere((s) => s.name == slotName);
  }

  int findSlotIndex(String slotName) {
    for (int i = 0; i < slots.length; i++) {
      if (slots[i].name == slotName) return i;
    }
    return -1;
  }

  // --- Skins.

  Skin? findSkin(String skinName) {
    return skins.firstWhere((s) => s.name == skinName);
  }

  // --- Events.

  EventData? findEvent(String eventName) {
    return events.firstWhere((e) => e.name == eventName);
  }

  // --- Animations.

  Animation? findAnimation(String animationName) {
    return animations.firstWhere((a) => a.name == animationName);
  }

  // --- IK constraints.

  IkConstraintData? findIkConstraint(String constraintName) {
    return ikConstraints.firstWhere((i) => i.name == constraintName);
  }

  // --- Transform constraints.

  TransformConstraintData? findTransformConstraint(String constraintName) {
    return transformConstraints.firstWhere((t) => t.name == constraintName);
  }

  int findTransformConstraintIndex(String constraintName) {
    for (int i = 0; i < this.transformConstraints.length; i++) {
      if (this.transformConstraints[i].name == constraintName) return i;
    }
    return -1;
  }

  // --- Path constraints.

  PathConstraintData? findPathConstraint(String constraintName) {
    return this.pathConstraints.firstWhere((p) => p.name == constraintName);
  }

  int findPathConstraintIndex(String constraintName) {
    for (int i = 0; i < this.pathConstraints.length; i++) {
      if (this.pathConstraints[i].name == constraintName) return i;
    }
    return -1;
  }

  @override
  String toString() => name ?? super.toString();
}
