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


class SkeletonData {

  String name = "";
  String version = "";
  String hash = "";
  num width = 0.0;
  num height = 0.0;

  List<BoneData> bones = new List<BoneData>(); // Ordered parents first.
  List<SlotData> slots = new List<SlotData>(); // Setup pose draw order.
  List<Skin> skins = new List<Skin>();
  List<EventData> events = new List<EventData>();
  List<Animation> animations = new List<Animation>();
  List<IkConstraintData> ikConstraints = new List<IkConstraintData>();
  
  Skin defaultSkin = null;

  // --- Bones.

  BoneData findBone(String boneName) {
    if (boneName == null) throw new ArgumentError("boneName cannot be null.");
    return bones.firstWhere((b) => b.name == boneName, orElse: () => null);
  }

  int findBoneIndex(String boneName) {
    if (boneName == null) throw new ArgumentError("boneName cannot be null.");
    for (int i = 0; i < bones.length; i++) {
      if (bones[i].name == boneName) return i;
    }
    return -1;
  }

  // --- Slots.

  SlotData findSlot(String slotName) {
    if (slotName == null) throw new ArgumentError("slotName cannot be null.");
    return slots.firstWhere((s) => s.name == slotName, orElse: () => null);
  }

  int findSlotIndex(String slotName) {
    if (slotName == null) throw new ArgumentError("slotName cannot be null.");
    for (int i = 0; i < slots.length; i++) {
      if (slots[i].name == slotName) return i;
    }
    return -1;
  }

  // --- Skins.

  Skin findSkin(String skinName) {
    if (skinName == null) throw new ArgumentError("skinName cannot be null.");
    return skins.firstWhere((s) => s.name == skinName, orElse: () => null);
  }

  // --- Events.

  EventData findEvent(String eventName) {
    if (eventName == null) throw new ArgumentError("eventName cannot be null.");
    return events.firstWhere((e) => e.name == eventName, orElse: () => null);
  }

  // --- Animations.

  Animation findAnimation(String animationName) {
    if (animationName == null) throw new ArgumentError("animationName cannot be null.");
    return animations.firstWhere((a) => a.name == animationName, orElse: () => null);
  }

  // --- IK constraints.

  IkConstraintData findIkConstraint (String ikConstraintName) {
    if (ikConstraintName == null) throw new ArgumentError("ikConstraintName cannot be null.");
    return ikConstraints.firstWhere((i) => i.name == ikConstraintName, orElse: () => null);
  }
  
  // ---

  String toString() => name != null ? name : super.toString();

}
