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

class Skeleton {

  final SkeletonData data;
  final List<Bone> bones = new List<Bone>();
  final List<Slot> slots = new List<Slot>();
  final List<Slot> drawOrder = new List<Slot>();
  final List<IkConstraint> ikConstraints = new List<IkConstraint>();
  final List<TransformConstraint> transformConstraints = new List<TransformConstraint>();
  final List<Updatable> _updateCache = new List<Updatable>();

  Skin _skin = null;

  num r = 1.0;
  num g = 1.0;
  num b = 1.0;
  num a = 1.0;

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

    for (TransformConstraintData transformConstraintData in data.transformConstraints) {
      TransformConstraint transformConstraint = new TransformConstraint(transformConstraintData, this);
      transformConstraints.add(transformConstraint);
    }

    updateCache();
  }

  /// Caches information about bones and constraints. Must be called if bones
  /// or constraints are added or removed.

  void updateCache() {

    _updateCache.clear();

    for (Bone bone in bones) {
      _updateCache.add(bone);
      for (var ikConstraint in ikConstraints) {
        if (bone == ikConstraint.bones.last) {
          _updateCache.add(ikConstraint);
          break;
        }
      }
    }

    for (var transformConstraint in transformConstraints) {
      for (int i = _updateCache.length - 1; i >= 0; i--) {
        var updatable = _updateCache[i];
        if (updatable == transformConstraint.bone ||
            updatable == transformConstraint.target) {
          _updateCache.insert(i + 1, transformConstraint);
          break;
        }
      }
    }
  }

  /// Updates the world transform for each bone and applies constraints.

  void updateWorldTransform() {
    for (Updatable updatable in _updateCache) {
      updatable.update();
    }
  }

  /// Sets the bones, constraints, and slots to their setup pose values.

  void setToSetupPose() {
    setBonesToSetupPose();
    setSlotsToSetupPose();
  }

  /// Sets the bones and constraints to their setup pose values.

  void setBonesToSetupPose() {

    for (Bone bone in bones) {
      bone.setToSetupPose();
    }

    for (IkConstraint ikConstraint in ikConstraints) {
      ikConstraint.bendDirection = ikConstraint.data.bendDirection;
      ikConstraint.mix = ikConstraint.data.mix;
    }

    for (TransformConstraint transformConstraint in transformConstraints) {
      transformConstraint.translateMix = transformConstraint.data.translateMix;
      transformConstraint.x = transformConstraint.data.x;
      transformConstraint.y = transformConstraint.data.y;
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

  IkConstraint findIkConstraint (String constraintName) {
    if (constraintName == null) throw new ArgumentError("constraintName cannot be null.");
    for (IkConstraint ikConstraint in ikConstraints) {
      if (ikConstraint.data.name == constraintName) return ikConstraint;
    }
    return null;
  }

  TransformConstraint findTransformConstraint(String constraintName) {
    if (constraintName == null) throw new ArgumentError("constraintName cannot be null.");
    for (TransformConstraint transformConstraint in transformConstraints) {
      if (transformConstraint.data.name == constraintName) return transformConstraint;
    }
    return null;
  }

  void update(num delta) {
    time += delta;
  }

  String toString() {
    return this.data.name != null ? this.data.name : super.toString();
  }
}
