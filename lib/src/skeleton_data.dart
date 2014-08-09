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

  String name;
  List<BoneData> bones = new List<BoneData>(); // Ordered parents first.
  List<SlotData> slots = new List<SlotData>(); // Setup pose draw order.
  List<Skin> skins = new List<Skin>();
  Skin defaultSkin;
  List<EventData> events = new List<EventData>();
  List<Animation> animations = new List<Animation>();

  // --- Bones.

  void addBone(BoneData bone) {
    if (bone == null) throw new ArgumentError("bone cannot be null.");
    bones.add(bone);
  }

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

  void addSlot(SlotData slot) {
    if (slot == null) throw new ArgumentError("slot cannot be null.");
    slots.add(slot);
  }

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

  void addSkin(Skin skin) {
    if (skin == null) throw new ArgumentError("skin cannot be null.");
    skins.add(skin);
  }

  Skin findSkin(String skinName) {
    if (skinName == null) throw new ArgumentError("skinName cannot be null.");
    return skins.firstWhere((s) => s.name == skinName, orElse: () => null);
  }

  // --- Events.

  void addEvent(EventData eventData) {
    if (eventData == null) throw new ArgumentError("eventData cannot be null.");
    events.add(eventData);
  }

  EventData findEvent(String eventName) {
    if (eventName == null) throw new ArgumentError("eventName cannot be null.");
    return events.firstWhere((e) => e.name == eventName, orElse: () => null);
  }

  // --- Animations.

  void addAnimation(Animation animation) {
    if (animation == null) throw new ArgumentError("animation cannot be null.");
    animations.add(animation);
  }

  Animation findAnimation(String animationName) {
    if (animationName == null) throw new ArgumentError("animationName cannot be null.");
    return animations.firstWhere((a) => a.name == animationName, orElse: () => null);
  }

  // ---

  String toString() => name != null ? name : super.toString();

}
