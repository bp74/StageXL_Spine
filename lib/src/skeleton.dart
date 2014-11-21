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

class Skeleton {

  final SkeletonData data;
  final List<Bone> bones = new List<Bone>();
  final List<Slot> slots = new List<Slot>();
  final List<Slot> drawOrder = new List<Slot>();
  final List<IkConstraint> ikConstraints = new List<IkConstraint>();
  final List<List<Bone>> _boneCache = new List<List<Bone>>();

  Skin _skin = null;

  num r = 1.0;
  num g = 1.0;
  num b = 1.0;
  num a = 1.0;

  bool flipX = false;
  bool flipY = false;
  num time = 0.0;
  num x = 0;
  num y = 0;

  Skeleton(this.data) {
    if (data == null) throw new ArgumentError("data cannot be null.");

    for (BoneData boneData in data.bones) {
      Bone parent = boneData.parent == null
          ? null : this.bones[this.data.bones.indexOf(boneData.parent)];
      this.bones.add(new Bone(boneData, this, parent));
    }

    for (SlotData slotData in data.slots) {
      Bone bone = this.bones[data.bones.indexOf(slotData.boneData)];
      Slot slot = new Slot(slotData, bone);
      this.slots.add(slot);
      this.drawOrder.add(slot);
    }

    for (IkConstraintData ikConstraintData in data.ikConstraints) {
      IkConstraint ikConstraint = new IkConstraint(ikConstraintData, this);
      ikConstraints.add(ikConstraint);
    }

    updateCache();
  }

  /// Caches information about bones and IK constraints. Must be called if
  /// bones or IK constraints are added or removed.
  ///
  void updateCache() {

    int ikConstraintsCount = ikConstraints.length;
    int arrayCount = ikConstraintsCount + 1;

    if (_boneCache.length > arrayCount) {
      _boneCache.length = arrayCount;
    }

    for (List<Bone> cachedBones in _boneCache) {
      cachedBones.clear();
    }

    while (_boneCache.length < arrayCount){
      _boneCache.add(new List<Bone>());
    }

    List<Bone> nonIkBones = _boneCache[0];

    outer:
    for (Bone bone in bones) {
      Bone current = bone;
      do {
        int ii = 0;
        for (IkConstraint ikConstraint in ikConstraints) {
          Bone parent = ikConstraint.bones[0];
          Bone child = ikConstraint.bones[ikConstraint.bones.length - 1];
          while (true) {
            if (current == child) {
              _boneCache[ii + 0].add(bone);
              _boneCache[ii + 1].add(bone);
              continue outer;
            }
            if (child == parent) break;
            child = child.parent;
          }
          ii++;
        }
        current = current.parent;
      } while (current != null);
      nonIkBones.add(bone);
    }
  }

  /// Updates the world transform for each bone and applies IK constraints.
  ///
  void updateWorldTransform() {

    for(int i = 0; i < this.bones.length; i++) {
      var bone = this.bones[i];
      if (bone is! Bone) continue; // dart2js_hint
      bone.rotationIK = bone.rotation;
    }

    for(int i = 0 ; i < _boneCache.length; i++) {

      var boneCache = _boneCache[i];
      for(int i = 0; i < boneCache.length; i++) {
        var bone = boneCache[i];
        if (bone is! Bone) continue; // dart2js_hint
        bone.updateWorldTransform();
      }

      if (i < ikConstraints.length) {
        ikConstraints[i].apply();
      }
    }
  }

  /// Sets the bones and slots to their setup pose values.
  ///
  void setToSetupPose() {
    setBonesToSetupPose();
    setSlotsToSetupPose();
  }

  void setBonesToSetupPose() {
    for (Bone bone in bones) {
      bone.setToSetupPose();
    }
    for (IkConstraint ikConstraint in ikConstraints) {
      ikConstraint.bendDirection = ikConstraint.data.bendDirection;
      ikConstraint.mix = ikConstraint.data.mix;
    }
  }

  void setSlotsToSetupPose() {
    int i = 0;
    for (Slot slot in this.slots) {
      drawOrder[i++] = slot;
      slot.setToSetupPose();
    }
  }

  Skin get skin => _skin;

  Bone get rootBone => this.bones.length == 0 ? null : this.bones[0];

  Bone findBone(String boneName) {
    if (boneName == null) throw new ArgumentError("boneName cannot be null.");
    return this.bones.firstWhere((b) => b.data.name == boneName, orElse: () => null);
  }

  int findBoneIndex(String boneName) {
    if (boneName == null) throw new ArgumentError("boneName cannot be null.");
    for (int i = 0; i < this.bones.length; i++) {
      if (this.bones[i].data.name == boneName) return i;
    }
    return -1;
  }

  Slot findSlot(String slotName) {
    if (slotName == null) throw new ArgumentError("slotName cannot be null.");
    return this.slots.firstWhere((s) => s.data.name == slotName, orElse: () => null);
  }

  int findSlotIndex(String slotName) {
    if (slotName == null) throw new ArgumentError("slotName cannot be null.");
    for (int i = 0; i < this.slots.length; i++) {
      if (this.slots[i].data.name == slotName) return i;
    }
    return -1;
  }

  void set skinName(String skinName) {
    Skin skin = data.findSkin(skinName);
    if (skin == null) throw new ArgumentError("Skin not found: $skinName");
    this.skin = skin;
  }

  String get skinName => skin == null ? null : skin.name;

  /// Sets the skin used to look up attachments before looking in
  /// the [SkeletonData.defaultSkin] default skin. Attachments from
  /// the new skin are attached if the corresponding attachment from the
  /// old skin was attached. If there was no old skin, each slot's setup
  /// mode attachment is attached from the new skin.

  void set skin(Skin newSkin) {
    if (newSkin != null) {
      if (_skin != null) {
        newSkin.attachAll(this, _skin);
      } else {
        for (int i = 0; i < this.slots.length; i++) {
          Slot slot = this.slots[i];
          String name = slot.data.attachmentName;
          if (name != null) {
            Attachment attachment = newSkin.getAttachment(i, name);
            if (attachment != null) slot.attachment = attachment;
          }
        }
      }
    }
    _skin = newSkin;
  }


  Attachment getAttachmentForSlotName(String slotName, String attachmentName) {
    return getAttachmentForSlotIndex(data.findSlotIndex(slotName), attachmentName);
  }

  Attachment getAttachmentForSlotIndex(int slotIndex, String attachmentName) {
    if (attachmentName == null) {
      throw new ArgumentError("attachmentName cannot be null.");
    }
    if (_skin != null) {
      Attachment attachment = _skin.getAttachment(slotIndex, attachmentName);
      if (attachment != null) return attachment;
    }
    if (data.defaultSkin != null) {
      return data.defaultSkin.getAttachment(slotIndex, attachmentName);
    }
    return null;
  }

  void setAttachment(String slotName, String attachmentName) {

    if (slotName == null) {
      throw new ArgumentError("slotName cannot be null.");
    }

    for (int i = 0; i < this.slots.length; i++) {
      Slot slot = this.slots[i];
      if (slot.data.name == slotName) {
        Attachment attachment = null;
        if (attachmentName != null) {
          attachment = getAttachmentForSlotIndex(i, attachmentName);
          if (attachment == null) {
            throw new ArgumentError("Attachment not found: $attachmentName, for slot: $slotName");
          }
        }
        slot.attachment = attachment;
        return;
      }
    }

    throw new ArgumentError("Slot not found: $slotName");
  }

  IkConstraint findIkConstraint (String ikConstraintName) {
    if (ikConstraintName == null) {
      throw new ArgumentError("ikConstraintName cannot be null.");
    }
    return this.ikConstraints.firstWhere((i) => i.data.name == ikConstraintName, orElse: () => null);
  }

  void update(num delta) {
    time += delta;
  }

  String toString() {
    return this.data.name != null ? this.data.name : super.toString();
  }
}
