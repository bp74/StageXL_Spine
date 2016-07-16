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
  final List<IkConstraint> ikConstraintsSorted = new List<IkConstraint>();
  final List<TransformConstraint> transformConstraints = new List<TransformConstraint>();
  final List<PathConstraint> pathConstraints = new List<PathConstraint>();
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
      if (boneData.parent == null) {
        Bone bone = new Bone(boneData, this, null);
        bones.add(bone);
      } else {
        Bone parent = bones[boneData.parent.index];
        Bone bone = new Bone(boneData, this, parent);
        parent.children.add(bone);
        bones.add(bone);
      }
    }

    for (SlotData slotData in data.slots) {
      Bone bone = this.bones[slotData.boneData.index];
      Slot slot = new Slot(slotData, bone);
      this.slots.add(slot);
      this.drawOrder.add(slot);
    }

    for (IkConstraintData ikConstraintData in data.ikConstraints) {
      var ikConstraint = new IkConstraint(ikConstraintData, this);
      ikConstraints.add(ikConstraint);
    }

    for (TransformConstraintData transformConstraintData
        in data.transformConstraints) {
      var transformConstraint =
          new TransformConstraint(transformConstraintData, this);
      transformConstraints.add(transformConstraint);
    }

    for (PathConstraintData pathConstraintData in data.pathConstraints) {
      var pathConstraint = new PathConstraint(pathConstraintData, this);
      pathConstraints.add(pathConstraint);
    }

    updateCache();
  }

  /// Caches information about bones and constraints.
  /// Must be called if bones, constraints, or weighted path attachments are
  /// added or removed.

  void updateCache() {
    List<Updatable> updateCache = _updateCache;
    updateCache.clear();

    List<Bone> bones = this.bones;
    for (int i = 0; i < bones.length; i++) {
      bones[i]._sorted = false;
    }

    // IK first, lowest hierarchy depth first.
    List<IkConstraint> ikConstraints = this.ikConstraintsSorted;
    ikConstraints.clear();
    for (IkConstraint c in this.ikConstraints) {
      ikConstraints.add(c);
    }

    for (int i = 0; i < ikConstraints.length; i++) {
      IkConstraint ik = ikConstraints[i];
      Bone bone = ik.bones[0].parent;
      int level = 0;
      for (; bone != null; level++) {
        bone = bone.parent;
      }
      ik.level = level;
    }

    for (int i = 1; i < ikConstraints.length; i++) {
      IkConstraint ik = ikConstraints[i];
      int level = ik.level;
      int ii = i - 1;
      for (; ii >= 0; ii--) {
        IkConstraint other = ikConstraints[ii];
        if (other.level < level) break;
        ikConstraints[ii + 1] = other;
      }
      ikConstraints[ii + 1] = ik;
    }
    for (int i = 0; i < ikConstraints.length; i++) {
      IkConstraint ikConstraint = ikConstraints[i];
      Bone target = ikConstraint.target;
      _sortBone(target);

      List<Bone> constrained = ikConstraint.bones;
      Bone parent = constrained[0];
      _sortBone(parent);

      updateCache.add(ikConstraint);

      _sortReset(parent.children);
      constrained.last._sorted = true;
    }

    List<PathConstraint> pathConstraints = this.pathConstraints;
    for (int i = 0; i < pathConstraints.length; i++) {
      PathConstraint pathConstraint = pathConstraints[i];

      Slot slot = pathConstraint.target;
      int slotIndex = slot.data.index;
      Bone slotBone = slot.bone;
      if (skin != null)
        _sortPathConstraintAttachment(skin, slotIndex, slotBone);
      if (data.defaultSkin != null && data.defaultSkin != skin) {
        _sortPathConstraintAttachment(data.defaultSkin, slotIndex, slotBone);
      }

      for (int ii = 0; ii < data.skins.length; ii++) {
        _sortPathConstraintAttachment(data.skins[ii], slotIndex, slotBone);
      }

      PathAttachment attachment = slot.attachment as PathAttachment;
      if (attachment != null)
        _sortPathConstraintAttachment2(attachment, slotBone);

      List<Bone> constrained = pathConstraint.bones;

      for (int ii = 0; ii < constrained.length; ii++) {
        _sortBone(constrained[ii]);
      }

      updateCache.add(pathConstraint);

      for (int ii = 0; ii < constrained.length; ii++) {
        _sortReset(constrained[ii].children);
      }

      for (int ii = 0; ii < constrained.length; ii++) {
        constrained[ii]._sorted = true;
      }
    }

    List<TransformConstraint> transformConstraints = this.transformConstraints;
    for (int i = 0; i < transformConstraints.length; i++) {
      TransformConstraint transformConstraint = transformConstraints[i];
      _sortBone(transformConstraint.target);
      List<Bone> constrained = transformConstraint.bones;
      for (int ii = 0; ii < constrained.length; ii++) {
        _sortBone(constrained[ii]);
      }
      updateCache.add(transformConstraint);
      for (int ii = 0; ii < constrained.length; ii++) {
        _sortReset(constrained[ii].children);
      }
      for (int ii = 0; ii < constrained.length; ii++) {
        constrained[ii]._sorted = true;
      }
    }

    for (int i = 0, n = bones.length; i < n; i++) {
      _sortBone(bones[i]);
    }
  }

  void _sortPathConstraintAttachment(Skin skin, int slotIndex, Bone slotBone) {
    var dict = skin.attachments[slotIndex];
    if (dict == null) return;
    for (Attachment value in dict.values) {
      _sortPathConstraintAttachment2(value, slotBone);
    }
  }

  void _sortPathConstraintAttachment2(Attachment attachment, Bone slotBone) {
    if (attachment is! PathAttachment) return;
    PathAttachment pathAttachment = attachment;
    Int16List pathBones = pathAttachment.bones;
    if (pathBones == null) {
      _sortBone(slotBone);
    } else {
      List<Bone> bones = this.bones;
      for (int boneIndex in pathBones) {
        _sortBone(bones[boneIndex]);
      }
    }
  }

  void _sortBone(Bone bone) {
    if (bone._sorted) return;
    Bone parent = bone.parent;
    if (parent != null) _sortBone(parent);
    bone._sorted = true;
    _updateCache.add(bone);
  }

  void _sortReset(List<Bone> bones) {
    for (int i = 0; i < bones.length; i++) {
      Bone bone = bones[i];
      if (bone._sorted) _sortReset(bone.children);
      bone._sorted = false;
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
      transformConstraint.rotateMix = transformConstraint.data.rotateMix;
      transformConstraint.translateMix = transformConstraint.data.translateMix;
      transformConstraint.scaleMix = transformConstraint.data.scaleMix;
      transformConstraint.shearMix = transformConstraint.data.shearMix;
    }

    for (PathConstraint pathConstraint in pathConstraints) {
      pathConstraint.position = pathConstraint.data.position;
      pathConstraint.spacing = pathConstraint.data.spacing;
      pathConstraint.rotateMix = pathConstraint.data.rotateMix;
      pathConstraint.translateMix = pathConstraint.data.translateMix;
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
    return this
        .bones
        .firstWhere((b) => b.data.name == boneName, orElse: () => null);
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
    return this
        .slots
        .firstWhere((s) => s.data.name == slotName, orElse: () => null);
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
    return getAttachmentForSlotIndex(
        data.findSlotIndex(slotName), attachmentName);
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
            throw new ArgumentError(
                "Attachment not found: $attachmentName, for slot: $slotName");
          }
        }
        slot.attachment = attachment;
        return;
      }
    }

    throw new ArgumentError("Slot not found: $slotName");
  }

  IkConstraint findIkConstraint(String constraintName) {
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

  PathConstraint findPathConstraint(String constraintName)  {
    if (constraintName == null) throw new ArgumentError("constraintName cannot be null.");
    for (PathConstraint pathConstraint in pathConstraints) {
      if (pathConstraint.data.name == constraintName) return pathConstraint;
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
