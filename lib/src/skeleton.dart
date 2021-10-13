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

class Skeleton {
  final SkeletonData data;
  final List<Bone> bones = [];
  final List<Slot> slots = [];
  final List<Slot> drawOrder = [];
  final List<IkConstraint> ikConstraints = [];
  final List<TransformConstraint> transformConstraints = [];
  final List<PathConstraint> pathConstraints = [];
  final List<Updatable> _updateCache = [];
  final List<Bone> _updateCacheReset = [];

  Skin? _skin;

  SpineColor color = SpineColor(1.0, 1.0, 1.0, 1.0);
  double time = 0.0;
  double x = 0.0;
  double y = 0.0;

  Skeleton(this.data) {
    for (BoneData boneData in data.bones) {
      if (boneData.parent == null) {
        Bone bone = Bone(boneData, this, null);
        bones.add(bone);
      } else {
        Bone parent = bones[boneData.parent!.index];
        Bone bone = Bone(boneData, this, parent);
        parent.children.add(bone);
        bones.add(bone);
      }
    }

    for (SlotData slotData in data.slots) {
      Bone bone = this.bones[slotData.boneData.index];
      Slot slot = Slot(slotData, bone);
      this.slots.add(slot);
      this.drawOrder.add(slot);
    }

    for (IkConstraintData ikConstraintData in data.ikConstraints) {
      var ikConstraint = IkConstraint(ikConstraintData, this);
      ikConstraints.add(ikConstraint);
    }

    for (TransformConstraintData transformConstraintData in data.transformConstraints) {
      var transformConstraint = TransformConstraint(transformConstraintData, this);
      transformConstraints.add(transformConstraint);
    }

    for (PathConstraintData pathConstraintData in data.pathConstraints) {
      var pathConstraint = PathConstraint(pathConstraintData, this);
      pathConstraints.add(pathConstraint);
    }

    updateCache();
  }

  /// Caches information about bones and constraints. Must be called if bones,
  /// constraints, or weighted path attachments are added or removed.

  void updateCache() {
    _updateCache.clear();
    _updateCacheReset.clear();

    for (var bone in this.bones) {
      bone._sorted = false;
    }

    // IK first, lowest hierarchy depth first.
    List<IkConstraint> ikConstraints = this.ikConstraints;
    List<TransformConstraint> transformConstraints = this.transformConstraints;
    List<PathConstraint> pathConstraints = this.pathConstraints;
    int ikCount = ikConstraints.length;
    int transformCount = transformConstraints.length;
    int pathCount = pathConstraints.length;
    int constraintCount = ikCount + transformCount + pathCount;

    outer:
    for (int i = 0; i < constraintCount; i++) {
      for (int ii = 0; ii < ikCount; ii++) {
        IkConstraint ikConstraint = ikConstraints[ii];
        if (ikConstraint.data.order == i) {
          _sortIkConstraint(ikConstraint);
          continue outer;
        }
      }
      for (int ii = 0; ii < transformCount; ii++) {
        TransformConstraint transformConstraint = transformConstraints[ii];
        if (transformConstraint.data.order == i) {
          _sortTransformConstraint(transformConstraint);
          continue outer;
        }
      }
      for (int ii = 0; ii < pathCount; ii++) {
        PathConstraint pathConstraint = pathConstraints[ii];
        if (pathConstraint.data.order == i) {
          _sortPathConstraint(pathConstraint);
          continue outer;
        }
      }
    }

    for (var bone in this.bones) {
      _sortBone(bone);
    }
  }

  void _sortIkConstraint(IkConstraint constraint) {
    Bone target = constraint.target;
    _sortBone(target);

    List<Bone> constrained = constraint.bones;
    Bone parent = constrained[0];
    _sortBone(parent);

    if (constrained.length > 1) {
      Bone child = constrained[constrained.length - 1];
      if (_updateCache.contains(child) == false) {
        _updateCacheReset.add(child);
      }
    }

    _updateCache.add(constraint);

    _sortReset(parent.children);
    constrained[constrained.length - 1]._sorted = true;
  }

  void _sortPathConstraint(PathConstraint constraint) {
    Slot slot = constraint.target;
    int slotIndex = slot.data.index;
    Bone slotBone = slot.bone;

    if (skin != null) {
      _sortPathConstraintAttachment(skin!, slotIndex, slotBone);
    }

    if (data.defaultSkin != null && data.defaultSkin != skin) {
      _sortPathConstraintAttachment(data.defaultSkin!, slotIndex, slotBone);
    }

    for (int i = 0; i < data.skins.length; i++) {
      _sortPathConstraintAttachment(data.skins[i], slotIndex, slotBone);
    }

    Attachment? attachment = slot.attachment;
    if (attachment is PathAttachment) {
      _sortPathConstraintAttachment2(attachment, slotBone);
    }

    List<Bone> constrained = constraint.bones;
    for (int i = 0; i < constrained.length; i++) {
      _sortBone(constrained[i]);
    }

    _updateCache.add(constraint);

    for (int ii = 0; ii < constrained.length; ii++) {
      _sortReset(constrained[ii].children);
    }
    for (int i = 0; i < constrained.length; i++) {
      constrained[i]._sorted = true;
    }
  }

  void _sortTransformConstraint(TransformConstraint constraint) {
    _sortBone(constraint.target);

    List<Bone> constrained = constraint.bones;

    if (constraint.data.local) {
      for (int i = 0; i < constrained.length; i++) {
        Bone child = constrained[i];
        _sortBone(child.parent!);
        if (_updateCache.contains(child) == false) {
          _updateCacheReset.add(child);
        }
      }
    } else {
      for (int i = 0; i < constrained.length; i++) {
        _sortBone(constrained[i]);
      }
    }

    _updateCache.add(constraint);

    for (int i = 0; i < constrained.length; i++) {
      _sortReset(constrained[i].children);
    }

    for (int i = 0; i < constrained.length; i++) {
      constrained[i]._sorted = true;
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
    Int16List? pathBones = pathAttachment.bones;
    if (pathBones == null) {
      _sortBone(slotBone);
    } else {
      List<Bone> bones = this.bones;
      int i = 0;
      while (i < pathBones.length) {
        int boneCount = pathBones[i++];
        for (int n = i + boneCount; i < n; i++) {
          _sortBone(bones[pathBones[i]]);
        }
      }
    }
  }

  void _sortBone(Bone bone) {
    if (bone._sorted) return;
    Bone? parent = bone.parent;
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
    for (Bone bone in _updateCacheReset) {
      bone.ax = bone.x;
      bone.ay = bone.y;
      bone.arotation = bone.rotation;
      bone.ascaleX = bone.scaleX;
      bone.ascaleY = bone.scaleY;
      bone.ashearX = bone.shearX;
      bone.ashearY = bone.shearY;
      bone.appliedValid = true;
    }
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

  Skin? get skin => _skin;

  Bone? get rootBone => bones.isEmpty ? null : bones.first;

  Bone? findBone(String boneName) {
    return this.bones.firstWhere((b) => b.data.name == boneName);
  }

  int findBoneIndex(String boneName) {
    for (int i = 0; i < this.bones.length; i++) {
      if (this.bones[i].data.name == boneName) return i;
    }
    return -1;
  }

  Slot? findSlot(String slotName) {
    return this.slots.firstWhere((s) => s.data.name == slotName);
  }

  int findSlotIndex(String slotName) {
    for (int i = 0; i < this.slots.length; i++) {
      if (this.slots[i].data.name == slotName) return i;
    }
    return -1;
  }

  set skinName(String? skinName) {
    if (skinName == null) throw ArgumentError('Cannot set skin name to null');
    Skin? skin = data.findSkin(skinName);
    if (skin == null) throw ArgumentError("Skin not found: $skinName");
    this.skin = skin;
  }

  String? get skinName => skin?.name;

  /// Sets the skin used to look up attachments before looking in
  /// the [SkeletonData.defaultSkin] default skin. Attachments from
  /// the new skin are attached if the corresponding attachment from the
  /// old skin was attached. If there was no old skin, each slot's setup
  /// mode attachment is attached from the new skin.

  set skin(Skin? newSkin) {
    if (newSkin != null) {
      if (_skin != null) {
        newSkin.attachAll(this, _skin!);
      } else {
        for (int i = 0; i < this.slots.length; i++) {
          Slot slot = this.slots[i];
          String? name = slot.data.attachmentName;
          if (name != null) {
            Attachment? attachment = newSkin.getAttachment(i, name);
            if (attachment != null) slot.attachment = attachment;
          }
        }
      }
    }
    _skin = newSkin;
  }

  Attachment? getAttachmentForSlotName(String slotName, String attachmentName) {
    return getAttachmentForSlotIndex(data.findSlotIndex(slotName), attachmentName);
  }

  Attachment? getAttachmentForSlotIndex(int slotIndex, String attachmentName) {
    if (_skin != null) {
      Attachment? attachment = _skin!.getAttachment(slotIndex, attachmentName);
      if (attachment != null) return attachment;
    }
    if (data.defaultSkin != null) {
      return data.defaultSkin!.getAttachment(slotIndex, attachmentName);
    }
    return null;
  }

  void setAttachment(String slotName, String attachmentName) {
    for (int i = 0; i < this.slots.length; i++) {
      Slot slot = this.slots[i];
      if (slot.data.name == slotName) {
        var attachment = getAttachmentForSlotIndex(i, attachmentName);
        if (attachment == null) {
          throw ArgumentError("Attachment not found: $attachmentName, for slot: $slotName");
        }
        slot.attachment = attachment;
        return;
      }
    }

    throw ArgumentError("Slot not found: $slotName");
  }

  IkConstraint? findIkConstraint(String constraintName) {
    for (IkConstraint ikConstraint in ikConstraints) {
      if (ikConstraint.data.name == constraintName) return ikConstraint;
    }
    return null;
  }

  TransformConstraint? findTransformConstraint(String constraintName) {
    for (TransformConstraint transformConstraint in transformConstraints) {
      if (transformConstraint.data.name == constraintName) return transformConstraint;
    }
    return null;
  }

  PathConstraint? findPathConstraint(String constraintName) {
    for (PathConstraint pathConstraint in pathConstraints) {
      if (pathConstraint.data.name == constraintName) return pathConstraint;
    }
    return null;
  }

  void update(double delta) {
    time += delta;
  }

  /*
  public function getBounds(offset : Vector.<Number>, size : Vector.<Number>, temp : Vector.<Number>) : void {
			if (offset == null) throw new ArgumentError("offset cannot be null.");
			if (size == null) throw new ArgumentError("size cannot be null.");
			var drawOrder : Vector.<Slot> = this.drawOrder;
			var minX : Number = Number.POSITIVE_INFINITY;
			var minY : Number = Number.POSITIVE_INFINITY;
			var maxX : Number = Number.NEGATIVE_INFINITY;
			var maxY : Number = Number.NEGATIVE_INFINITY;
			for (var i : int = 0, n : int = drawOrder.length; i < n; i++) {
				var slot : Slot = drawOrder[i];
				var verticesLength : int = 0;
				var vertices : Vector.<Number> = null;
				var attachment : Attachment = slot.attachment;
				if (attachment is RegionAttachment) {
					verticesLength = 8;
					temp.length = verticesLength;
					vertices = temp;
					(attachment as RegionAttachment).computeWorldVertices(slot.bone, vertices, 0, 2);
				} else if (attachment is MeshAttachment) {
					var mesh : MeshAttachment = attachment as MeshAttachment;
					verticesLength = mesh.worldVerticesLength;
					temp.length = verticesLength;
					vertices = temp;
					mesh.computeWorldVertices(slot, 0, verticesLength, vertices, 0, 2);
				}
				if (vertices != null) {
					for (var ii : int = 0, nn : int = vertices.length; ii < nn; ii += 8) {
						var x : Number = vertices[ii], y : Number = vertices[ii + 1];
						minX = Math.min(minX, x);
						minY = Math.min(minY, y);
						maxX = Math.max(maxX, x);
						maxY = Math.max(maxY, y);
					}
				}
			}
			offset[0] = minX;
			offset[1] = minY;
			size[0] = maxX - minX;
			size[1] = maxY - minY;
		}
 */

  @override
  String toString() => this.data.name ?? super.toString();
}
