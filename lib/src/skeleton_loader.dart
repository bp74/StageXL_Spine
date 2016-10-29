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

class SkeletonLoader {

  final AttachmentLoader attachmentLoader;
  final List<_LinkedMesh> _linkedMeshes = new List<_LinkedMesh>();

  SkeletonLoader(this.attachmentLoader);

  /// Parameter 'object' must be a String or Map.
  ///
  SkeletonData readSkeletonData(dynamic object, [String name = null]) {

    Map root;

    if (object == null) {
      throw new ArgumentError("object cannot be null.");
    } else if (object is String) {
      root = JSON.decode(object);
    } else if (object is Map) {
      root = object;
    } else {
      throw new ArgumentError("object must be a String or Map.");
    }

    SkeletonData skeletonData = new SkeletonData();
    skeletonData.name = name;

    // Skeletion

    Map skeletonMap = root["skeleton"];

    if (skeletonMap != null) {
      skeletonData.version = _getString(skeletonMap, "spine", "");
      skeletonData.hash = _getString(skeletonMap, "hash", "");
      skeletonData.width = _getDouble(skeletonMap, "width", 0.0);
      skeletonData.height = _getDouble(skeletonMap, "height", 0.0);
      skeletonData.fps = _getDouble(skeletonMap, "fps", 0.0);
      skeletonData.imagesPath = _getString(skeletonMap, "images", "");
    }

    // Bones

    for (Map boneMap in root["bones"] ?? []) {

      BoneData parent = null;

      String parentName = _getString(boneMap, "parent", null);
      if (parentName != null) {
        parent = skeletonData.findBone(parentName);
        if (parent == null) throw new StateError("Parent bone not found: $parentName");
      }

      var boneIndex = skeletonData.bones.length;
      var boneName = _getString(boneMap, "name", null);
      var boneData = new BoneData(boneIndex, boneName, parent);
      var transformMode = "TransformMode." + _getString(boneMap, "transform",  "normal");

      boneData.length = _getDouble(boneMap, "length", 0.0);
      boneData.x = _getDouble(boneMap, "x", 0.0);
      boneData.y = _getDouble(boneMap, "y", 0.0);
      boneData.rotation = _getDouble(boneMap, "rotation", 0.0);
      boneData.scaleX = _getDouble(boneMap, "scaleX", 1.0);
      boneData.scaleY = _getDouble(boneMap, "scaleY", 1.0);
      boneData.shearX = _getDouble(boneMap, "shearX", 0.0);
      boneData.shearY = _getDouble(boneMap, "shearY", 0.0);
      boneData.transformMode = TransformMode.values.firstWhere((e) => e.toString() == transformMode);
      skeletonData.bones.add(boneData);
    }

    // Slots

    for (Map slotMap in root["slots"] ?? []) {

      var slotName = _getString(slotMap, "name", null);
      var boneName = _getString(slotMap, "bone", null);
      var boneData = skeletonData.findBone(boneName);
      if (boneData == null) throw new StateError("Slot bone not found: $boneName");

      var slotIndex = skeletonData.slots.length;
      SlotData slotData = new SlotData(slotIndex, slotName, boneData);
      String slotDataColor = _getString(slotMap, "color", "FFFFFFFF");
      slotData.r = _toColor(slotDataColor, 0);
      slotData.g = _toColor(slotDataColor, 1);
      slotData.b = _toColor(slotDataColor, 2);
      slotData.a = _toColor(slotDataColor, 3);
      slotData.attachmentName = _getString(slotMap, "attachment", null);

      switch(_getString(slotMap, "blend", "normal")) {
        case "normal": slotData.blendMode = BlendMode.NORMAL; break;
        case "additive": slotData.blendMode = BlendMode.ADD; break;
        case "multiply": slotData.blendMode = BlendMode.MULTIPLY; break;
        case "screen": slotData.blendMode = BlendMode.SCREEN; break;
      }

      skeletonData.slots.add(slotData);
    }

    // IK constraints.

    for (Map constraintMap in root["ik"] ?? []) {

      var constraintName = _getString(constraintMap, "name", null);
      var constraintData = new IkConstraintData(constraintName);

      for (var boneName in constraintMap["bones"]) {
        var bone = skeletonData.findBone(boneName);
        if (bone == null) throw new StateError("IK constraint bone not found: $boneName");
        constraintData.bones.add(bone);
      }

      var targetName = _getString(constraintMap, "target", null);
      var target = skeletonData.findBone(targetName);
      if (target == null) throw new StateError("Target bone not found: $targetName");

      constraintData.target = target;
      constraintData.order = _getInt(constraintMap, "order", 0);
      constraintData.bendDirection = _getBool(constraintMap, "bendPositive", true) ? 1 : -1;
      constraintData.mix = _getDouble(constraintMap, "mix", 1.0);

      skeletonData.ikConstraints.add(constraintData);
    }

    // Transform constraints.

    for (Map constraintMap in root["transform"] ?? []) {

      var constraintName = _getString(constraintMap, "name", null);
      var constraintData = new TransformConstraintData(constraintName);

      for (String boneName in constraintMap["bones"]) {
        var bone = skeletonData.findBone(boneName);
        if (bone == null) throw new StateError("Transform constraint bone not found: $boneName");
        constraintData.bones.add(bone);
      }

      var targetName = _getString(constraintMap, "target", null);
      var target = skeletonData.findBone(targetName);
      if (target == null) throw new StateError("Target bone not found: $targetName");

      constraintData.target = target;
      constraintData.order = _getInt(constraintMap, "order", 0);
      constraintData.offsetRotation = _getDouble(constraintMap, "rotation", 0.0);
      constraintData.offsetX = _getDouble(constraintMap, "x", 0.0);
      constraintData.offsetY = _getDouble(constraintMap, "y", 0.0);
      constraintData.offsetScaleX = _getDouble(constraintMap, "scaleX", 0.0);
      constraintData.offsetScaleY = _getDouble(constraintMap, "scaleY", 0.0);
      constraintData.offsetShearY = _getDouble(constraintMap, "shearY", 0.0);
      constraintData.rotateMix = _getDouble(constraintMap, "rotateMix", 1.0);
      constraintData.translateMix = _getDouble(constraintMap, "translateMix", 1.0);
      constraintData.scaleMix = _getDouble(constraintMap, "scaleMix", 1.0);
      constraintData.shearMix = _getDouble(constraintMap, "shearMix", 1.0);

      skeletonData.transformConstraints.add(constraintData);
    }

    // Path constraints.

    for (Map constraintMap in root["path"] ?? []) {

      var constraintName = _getString(constraintMap, "name", null);
      var pathConstraintData = new PathConstraintData(constraintName);

      for (String boneName in constraintMap["bones"]) {
        var bone = skeletonData.findBone(boneName);
        if (bone == null) throw new StateError("Path constraint bone not found: $boneName");
        pathConstraintData.bones.add(bone);
      }

      var targetName = _getString(constraintMap, "target", null);
      var target = skeletonData.findSlot(targetName);
      if (target == null) throw new StateError("Path target slot not found: $targetName");

      var positionMode = "PositionMode." + _getString(constraintMap, "positionMode", "percent");
      var spacingMode = "SpacingMode." + _getString(constraintMap, "spacingMode", "length");
      var rotateMode = "RotateMode." + _getString(constraintMap, "rotateMode", "tangent");

      pathConstraintData.target = target;
      pathConstraintData.order = _getInt(constraintMap, "order", 0);
      pathConstraintData.positionMode = PositionMode.values.firstWhere((e) => e.toString() == positionMode);
      pathConstraintData.spacingMode = SpacingMode.values.firstWhere((e) => e.toString() == spacingMode);
      pathConstraintData.rotateMode = RotateMode.values.firstWhere((e) => e.toString() == rotateMode);
      pathConstraintData.offsetRotation = _getDouble(constraintMap, "rotation", 0.0);
      pathConstraintData.position = _getDouble(constraintMap, "position", 0.0);
      pathConstraintData.spacing = _getDouble(constraintMap, "spacing", 0.0);
      pathConstraintData.rotateMix = _getDouble(constraintMap, "rotateMix", 1.0);
      pathConstraintData.translateMix = _getDouble(constraintMap, "translateMix", 1.0);

      skeletonData.pathConstraints.add(pathConstraintData);
    }

    // Skins

    Map skins = root["skins"] ?? {};

    for (String skinName in skins.keys) {
      var skinMap = skins[skinName];
      var skin = new Skin(skinName);
      for (String slotName in skinMap.keys) {
        var slotIndex = skeletonData.findSlotIndex(slotName);
        var slotEntry = skinMap[slotName];
        for (String attachmentName in slotEntry.keys) {
          var attachment = readAttachment(slotEntry[attachmentName], skin, slotIndex, attachmentName);
          if (attachment != null) skin.addAttachment(slotIndex, attachmentName, attachment);
        }
      }
      skeletonData.skins.add(skin);
      if (skin.name == "default") skeletonData.defaultSkin = skin;
    }

    // Linked meshes.

    for (var linkedMesh in _linkedMeshes) {
      var parentSkin = linkedMesh.skin == null ? skeletonData.defaultSkin : skeletonData.findSkin(linkedMesh.skin);
      if (parentSkin == null) throw new StateError("Skin not found: ${linkedMesh.skin}");
      var parentMesh = parentSkin.getAttachment(linkedMesh.slotIndex, linkedMesh.parent);
      if (parentMesh == null) throw new StateError("Parent mesh not found: ${linkedMesh.parent}");
      linkedMesh.mesh.parentMesh = parentMesh as MeshAttachment;
      linkedMesh.mesh.updateUVs();
    }

    _linkedMeshes.clear();

    // Events

    Map events = root["events"] ?? {};

    for (String eventName in events.keys) {
      Map eventMap = events[eventName];
      var eventData = new EventData(eventName);
      eventData.intValue = _getInt(eventMap, "int", 0);
      eventData.floatValue = _getDouble(eventMap, "float", 0.0);
      eventData.stringValue = _getString(eventMap, "string", "");
      skeletonData.events.add(eventData);
    }

    // Animations

    Map animations = root["animations"] ?? {};

    for (var animationName in animations.keys) {
      _readAnimation(animations[animationName], animationName, skeletonData);
    }

    return skeletonData;
  }

  //---------------------------------------------------------------------------

  Attachment readAttachment(Map map, Skin skin, int slotIndex, String name) {

    name = _getString(map, "name", name);

    var typeName = "AttachmentType." + _getString(map, "type", "region");
    var type = AttachmentType.values.firstWhere((e) => e.toString() == typeName);
    var path = _getString(map, "path", name);

    switch (type) {

      case AttachmentType.region:

        var region = attachmentLoader.newRegionAttachment(skin, name, path);
        if (region == null) return null;

        var regionColor = _getString(map, "color", "FFFFFFFF");

        region.x = _getDouble(map, "x", 0.0);
        region.y = _getDouble(map, "y", 0.0);
        region.scaleX = _getDouble(map, "scaleX", 1.0);
        region.scaleY = _getDouble(map, "scaleY", 1.0);
        region.rotation = _getDouble(map, "rotation", 0.0);
        region.width = _getDouble(map, "width", 0.0);
        region.height = _getDouble(map, "height", 0.0);
        region.r = _toColor(regionColor, 0);
        region.g = _toColor(regionColor, 1);
        region.b = _toColor(regionColor, 2);
        region.a = _toColor(regionColor, 3);
        region.update();

        return region;

      case AttachmentType.mesh:
      case AttachmentType.linkedmesh:

        var mesh = attachmentLoader.newMeshAttachment(skin, name, path);
        if (mesh == null) return null;

        var meshColor = _getString(map, "color", "FFFFFFFF");
        mesh.r = _toColor(meshColor, 0);
        mesh.g = _toColor(meshColor, 1);
        mesh.b = _toColor(meshColor, 2);
        mesh.a = _toColor(meshColor, 3);
        mesh.width = _getDouble(map, "width", 0.0);
        mesh.height = _getDouble(map, "height", 0.0);

        var parentName =_getString(map, "parent", null);
        var skinName = _getString(map, "skin", null);

        if (parentName != null) {
          var lm = new _LinkedMesh(mesh, skinName, slotIndex, parentName);
          _linkedMeshes.add(lm);
          mesh.inheritDeform = _getBool(map, "deform", true);
          return mesh;
        }

        Float32List uvs = _getFloat32List(map, "uvs");
        _readVertices(map, mesh, uvs.length);

        mesh.triangles = _getInt16List(map, "triangles");
        mesh.regionUVs = uvs;
        mesh.updateUVs();

        mesh.hullLength = _getInt(map, "hull", 0) * 2;
        if (map.containsKey("edges")) mesh.edges = _getInt16List(map, "edges");

        return mesh;

      case AttachmentType.boundingbox:

        var box = attachmentLoader.newBoundingBoxAttachment(skin, name);
        if (box == null) return null;
        int vertexCount = _getInt(map, "vertexCount", 0);
        _readVertices(map, box, vertexCount << 1);
        return box;

      case AttachmentType.path:

        var path = attachmentLoader.newPathAttachment(skin, name);
        if (path == null) return null;

        path.closed = _getBool(map, "closed", false);
        path.constantSpeed = _getBool(map, "constantSpeed", true);
        path.lengths = _getFloat32List(map, "lengths");

        int vertexCount = _getInt(map, "vertexCount", 0);
        _readVertices(map, path, vertexCount << 1);

        return path;
    }

    return null;
  }

  //---------------------------------------------------------------------------

  void _readVertices(Map map, VertexAttachment attachment, int verticesLength) {

    attachment.worldVerticesLength = verticesLength;

    var vertices = _getFloat32List(map, "vertices");
    var weights = new List<double>();
    var bones = new List<int>();

    if (verticesLength == vertices.length) {
      attachment.vertices = vertices;
      return;
    }

    for (int i = 0; i < vertices.length;) {
      int boneCount = vertices[i++].toInt();
      bones.add(boneCount);
      for (var nn = i + boneCount * 4; i < nn; i+=4) {
        bones.add(vertices[i + 0].toInt());
        weights.add(vertices[i + 1]);
        weights.add(vertices[i + 2]);
        weights.add(vertices[i + 3]);
      }
    }

    attachment.vertices = new Float32List.fromList(weights);
    attachment.bones = new Int16List.fromList(bones);
  }

  //---------------------------------------------------------------------------

  void _readAnimation (Map map, String name, SkeletonData skeletonData) {

    List<Timeline> timelines = new List<Timeline>();
    double duration = 0.0;

    //-------------------------------------

    Map slots = map["slots"] ?? {};

    for (String slotName in slots.keys) {

      Map slotMap = slots[slotName];
      int slotIndex = skeletonData.findSlotIndex(slotName);

      for (String timelineName in slotMap.keys) {

        List values = slotMap[timelineName];

        if (timelineName == "color") {

          ColorTimeline colorTimeline = new ColorTimeline(values.length);
          colorTimeline.slotIndex = slotIndex;

          int frameIndex = 0;
          for (Map valueMap in values) {
            double time = _getDouble(valueMap, "time", 0.0);
            String color = _getString(valueMap, "color", "FFFFFFFF");
            double r = _toColor(color, 0);
            double g = _toColor(color, 1);
            double b = _toColor(color, 2);
            double a = _toColor(color, 3);
            colorTimeline.setFrame(frameIndex, time, r, g, b, a);
            _readCurve(valueMap, colorTimeline, frameIndex);
            frameIndex++;
          }

          timelines.add(colorTimeline);
          duration = math.max(duration, colorTimeline.frames[(colorTimeline.frameCount - 1) * ColorTimeline._ENTRIES]);

        } else if (timelineName == "attachment") {

          AttachmentTimeline attachmentTimeline = new AttachmentTimeline(values.length);
          attachmentTimeline.slotIndex = slotIndex;

          int frameIndex = 0;
          for (Map valueMap in values) {
            double time = _getDouble(valueMap, "time", 0.0);
            String name = _getString(valueMap, "name", null);
            attachmentTimeline.setFrame(frameIndex++, time, name);
          }

          timelines.add(attachmentTimeline);
          duration = math.max(duration, attachmentTimeline.frames[attachmentTimeline.frameCount - 1]);

        } else {

          throw new StateError("Invalid timeline type for a slot: $timelineName ($slotName)");

        }
      }
    }

    //-------------------------------------

    Map bones = map["bones"] ?? {};

    for (String boneName in bones.keys) {

      int boneIndex = skeletonData.findBoneIndex(boneName);
      if (boneIndex == -1) throw new StateError("Bone not found: $boneName");

      Map boneMap = bones[boneName];

      for (String timelineName in boneMap.keys) {

        List values = boneMap[timelineName];

        if (timelineName == "rotate") {

          RotateTimeline rotateTimeline = new RotateTimeline(values.length);
          rotateTimeline.boneIndex = boneIndex;

          int frameIndex = 0;
          for (Map valueMap in values) {
            rotateTimeline.setFrame(frameIndex, valueMap["time"], valueMap["angle"]);
            _readCurve(valueMap, rotateTimeline, frameIndex);
            frameIndex++;
          }

          timelines.add(rotateTimeline);
          duration = math.max(duration, rotateTimeline.frames[(rotateTimeline.frameCount - 1) * RotateTimeline._ENTRIES]);

        } else if (timelineName == "translate" || timelineName == "scale" || timelineName == "shear") {

          TranslateTimeline translateTimeline;

          if (timelineName == "scale") {
            translateTimeline = new ScaleTimeline(values.length);
          } else if (timelineName == "shear") {
            translateTimeline = new ShearTimeline(values.length);
          } else {
            translateTimeline = new TranslateTimeline(values.length);
          }

          translateTimeline.boneIndex = boneIndex;

          int frameIndex = 0;
          for (Map valueMap in values) {
            double x = _getDouble(valueMap, "x", 0.0);
            double y = _getDouble(valueMap, "y", 0.0);
            double time = _getDouble(valueMap, "time", 0.0);
            translateTimeline.setFrame(frameIndex, time, x, y);
            _readCurve(valueMap, translateTimeline, frameIndex);
            frameIndex++;
          }

          timelines.add(translateTimeline);
          duration = math.max(duration, translateTimeline.frames[(translateTimeline.frameCount - 1) * TranslateTimeline._ENTRIES]);

        } else {

          throw new StateError("Invalid timeline type for a bone: $timelineName ($boneName)");

        }
      }
    }

    //-------------------------------------

    Map ikMap = map["ik"] ?? {};

    for (String ikConstraintName in ikMap.keys) {
      IkConstraintData ikConstraint = skeletonData.findIkConstraint(ikConstraintName);
      List valueMaps = ikMap[ikConstraintName];
      IkConstraintTimeline ikTimeline = new IkConstraintTimeline(valueMaps.length);
      ikTimeline.ikConstraintIndex = skeletonData.ikConstraints.indexOf(ikConstraint);
      int frameIndex = 0;
      for (Map valueMap in valueMaps) {
        double time = _getDouble(valueMap, "time", 0.0);
        double mix = _getDouble(valueMap, "mix", 1.0);
        int bendDirection = _getBool(valueMap, "bendPositive", true) ? 1 : -1;
        ikTimeline.setFrame(frameIndex, time, mix, bendDirection);
        _readCurve(valueMap, ikTimeline, frameIndex);
        frameIndex++;
      }
      timelines.add(ikTimeline);
      duration = math.max(duration, ikTimeline.frames[(ikTimeline.frameCount - 1) * IkConstraintTimeline._ENTRIES]);
    }

    //-------------------------------------

    Map transformMap = map["transform"] ?? {};

    for (String transformName in transformMap.keys) {
      TransformConstraintData transformConstraint = skeletonData.findTransformConstraint(transformName);
      List valueMaps = transformMap[transformName];
      TransformConstraintTimeline transformTimeline = new TransformConstraintTimeline(valueMaps.length);
      transformTimeline.transformConstraintIndex = skeletonData.transformConstraints.indexOf(transformConstraint);
      int frameIndex = 0;
      for (Map valueMap in valueMaps) {
        double rotateMix = _getDouble(valueMap, "rotateMix", 1.0);
        double translateMix = _getDouble(valueMap, "translateMix", 1.0);
        double scaleMix = _getDouble(valueMap, "scaleMix", 1.0);
        double shearMix = _getDouble(valueMap, "shearMix", 1.0);
        double time = _getDouble(valueMap, "time", 0.0);
        transformTimeline.setFrame(frameIndex, time, rotateMix, translateMix, scaleMix, shearMix);
        _readCurve(valueMap, transformTimeline, frameIndex);
        frameIndex++;
      }
      timelines.add(transformTimeline);
      duration = math.max(duration, transformTimeline.frames[(transformTimeline.frameCount - 1) * TransformConstraintTimeline._ENTRIES]);
    }

    //-------------------------------------

    Map pathsMaps = map["paths"] ?? {};

    for (String pathName in pathsMaps.keys) {

      int index = skeletonData.findPathConstraintIndex(pathName);
      if (index == -1) throw new StateError("Path constraint not found: $pathName");

      Map pathMap = pathsMaps[pathName];
      for (String timelineName in pathMap.keys) {

        List valueMaps = pathMap[timelineName];

        if (timelineName == "position" || timelineName == "spacing") {

          PathConstraintPositionTimeline pathTimeline;

          if (timelineName == "spacing") {
            pathTimeline = new PathConstraintSpacingTimeline(valueMaps.length);
          } else {
            pathTimeline = new PathConstraintPositionTimeline(valueMaps.length);
          }

          pathTimeline.pathConstraintIndex = index;
          int frameIndex = 0;

          for (Map valueMap in valueMaps) {
            double value = _getDouble(valueMap, timelineName, 0.0);
            double time = _getDouble(valueMap, "time", 0.0);
            pathTimeline.setFrame(frameIndex, time, value);
            _readCurve(valueMap, pathTimeline, frameIndex);
            frameIndex++;
          }

          timelines.add(pathTimeline);
          duration = math.max(duration, pathTimeline.frames[(pathTimeline.frameCount - 1) * PathConstraintPositionTimeline._ENTRIES]);

        } else if (timelineName == "mix") {

          PathConstraintMixTimeline pathMixTimeline = new PathConstraintMixTimeline(valueMaps.length);
          pathMixTimeline.pathConstraintIndex = index;
          int frameIndex = 0;

          for (Map valueMap in valueMaps) {
            double rotateMix = _getDouble(valueMap, "rotateMix", 1.0);
            double translateMix = _getDouble(valueMap, "translateMix", 1.0);
            double time = _getDouble(valueMap, "time", 0.0);
            pathMixTimeline.setFrame(frameIndex, time, rotateMix, translateMix);
            _readCurve(valueMap, pathMixTimeline, frameIndex);
            frameIndex++;
          }

          timelines.add(pathMixTimeline);
          duration = math.max(duration, pathMixTimeline.frames[(pathMixTimeline.frameCount - 1) * PathConstraintMixTimeline._ENTRIES]);
        }
      }
    }

    //-------------------------------------

    Map deformMap = map["deform"] ?? {};

    for (String skinName in deformMap.keys) {

      Skin skin = skeletonData.findSkin(skinName);
      Map slotMap = deformMap[skinName];

      for (String slotName in slotMap.keys) {
        int slotIndex = skeletonData.findSlotIndex(slotName);
        Map timelineMap = slotMap[slotName];

        for (String timelineName in timelineMap.keys) {

          List valueMaps = timelineMap[timelineName];
          VertexAttachment attachment = skin.getAttachment(slotIndex, timelineName);
          if (attachment == null) throw new StateError("Deform attachment not found: $timelineName");

          bool weighted = attachment.bones != null;
          Float32List vertices = attachment.vertices;
          int deformLength = weighted ? vertices.length ~/ 3 * 2 : vertices.length;
          int frameIndex = 0;

          DeformTimeline deformTimeline = new DeformTimeline(valueMaps.length);
          deformTimeline.slotIndex = slotIndex;
          deformTimeline.attachment = attachment;

          for (Map valueMap in valueMaps) {

            Float32List deform;
            var verticesValue = valueMap["vertices"];
            if (verticesValue == null) {
              deform = weighted ? new Float32List(deformLength) : vertices;
            } else {
              deform = new Float32List(deformLength);
              int start = _getInt(valueMap, "offset", 0);
              Float32List temp = _getFloat32List(valueMap, "vertices");
              for (int i = 0; i < temp.length; i++) {
                deform[start + i] = temp[i];
              }
              if (!weighted) {
                for (int i = 0; i < deformLength; i++) {
                  deform[i] += vertices[i];
                }
              }
            }
            var time = _getDouble(valueMap, "time", 0.0);
            deformTimeline.setFrame(frameIndex, time, deform);
            _readCurve(valueMap, deformTimeline, frameIndex);
            frameIndex++;
          }

          timelines.add(deformTimeline);
          duration = math.max(duration, deformTimeline.frames[deformTimeline.frameCount - 1]);
        }
      }
    }

    //-------------------------------------

    List drawOrderValues = map["drawOrder"] ?? map["draworder"];

    if (drawOrderValues != null) {

      DrawOrderTimeline drawOrderTimeline = new DrawOrderTimeline(drawOrderValues.length);
      int slotCount = skeletonData.slots.length;
      int frameIndex = 0;

      for (Map drawOrderMap in drawOrderValues) {

        double time = _getDouble(drawOrderMap, "time", 0.0);
        Int16List drawOrder = null;

        if (drawOrderMap.containsKey("offsets")) {

          drawOrder = new Int16List(slotCount);
          for(int i = 0; i < drawOrder.length; i++) {
            drawOrder[i] = -1;
          }

          List offsetMaps = drawOrderMap["offsets"];
          Int16List unchanged = new Int16List(slotCount - offsetMaps.length);
          int originalIndex = 0;
          int unchangedIndex = 0;

          for (Map offsetMap in offsetMaps) {
            String slotName = _getString(offsetMap, "slot", null);
            int slotIndex = skeletonData.findSlotIndex(slotName);
            if (slotIndex == -1) throw new StateError("Slot not found: $slotName");
            // Collect unchanged items.
            while (originalIndex != slotIndex) {
              unchanged[unchangedIndex++] = originalIndex++;
            }
            // Set changed items.
            drawOrder[originalIndex + offsetMap["offset"]] = originalIndex++;
          }

          // Collect remaining unchanged items.
          while (originalIndex < slotCount) {
            unchanged[unchangedIndex++] = originalIndex++;
          }

          // Fill in unchanged items.
          for (int i = slotCount - 1; i >= 0; i--) {
            if (drawOrder[i] == -1) drawOrder[i] = unchanged[--unchangedIndex];
          }
        }

        drawOrderTimeline.setFrame(frameIndex++, time, drawOrder);
      }

      timelines.add(drawOrderTimeline);
      duration = math.max(duration, drawOrderTimeline.frames[drawOrderTimeline.frameCount - 1]);
    }

    //-------------------------------------

    if (map.containsKey("events")) {

      List eventsMap = map["events"];
      EventTimeline eventTimeline = new EventTimeline(eventsMap.length);
      int frameIndex = 0;

      for (Map eventMap in eventsMap) {
        var eventData = skeletonData.findEvent(eventMap["name"]);
        if (eventData == null) throw new StateError("Event not found: ${eventMap["name"]}");
        var eventTime = _getDouble(eventMap, "time", 0.0);
        var event = new Event(eventTime, eventData);
        event.intValue = _getInt(eventMap, "int", eventData.intValue);
        event.floatValue = _getDouble(eventMap, "float", eventData.floatValue);
        event.stringValue = _getString(eventMap, "string", eventData.stringValue);
        eventTimeline.setFrame(frameIndex++, event);
      }

      timelines.add(eventTimeline);
      duration = math.max(duration, eventTimeline.frames[eventTimeline.frameCount - 1]);
    }

    skeletonData.animations.add(new Animation(name, timelines, duration));
  }

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------

  void _readCurve(Map valueMap, CurveTimeline timeline, int frameIndex) {
    var curve = valueMap["curve"];
    if (curve == null) {
      return;
    } else if (curve == "stepped") {
      timeline.setStepped(frameIndex);
    } else if (curve is List) {
      timeline.setCurve(frameIndex, curve[0], curve[1], curve[2], curve[3]);
    }
  }

  double _toColor(String hexString, int colorIndex) {
    if (hexString.length != 8) {
      throw new ArgumentError("Color hexidecimal length must be 8, recieved: $hexString");
    }
    var substring = hexString.substring(colorIndex * 2, colorIndex * 2 + 2);
    return int.parse(substring, radix: 16) / 255;
  }

  Float32List _getFloat32List(Map map, String name) {
    List values = map[name];
    Float32List result = new Float32List(values.length);
    for (int i = 0; i < values.length; i++) {
      result[i] = values[i].toDouble();
    }
    return result;
  }

  Int16List _getInt16List(Map map, String name) {
    List values = map[name];
    Int16List result = new Int16List(values.length);
    for (int i = 0; i < values.length; i++) {
      result[i] = values[i].toInt();
    }
    return result;
  }

  String _getString(Map map, String name, String defaultValue) {
    var value = map[name];
    return value is String ? value : defaultValue;
  }

  double _getDouble(Map map, String name, double defaultValue) {
    var value = map[name];
    if (value is num) {
      return value.toDouble();
    } else if (defaultValue is num) {
      return defaultValue.toDouble();
    } else {
      return 0.0;
    }
  }

  int _getInt(Map map, String name, int defaultValue) {
    var value = map[name];
    if (value is int) {
      return value;
    } else if (defaultValue is int) {
      return defaultValue;
    } else {
      return 0;
    }
  }

  bool _getBool(Map map, String name, bool defaultValue) {
    var value = map[name];
    if (value is bool) {
      return value;
    } else if (defaultValue is bool) {
      return defaultValue;
    } else {
      return false;
    }
  }
}

class _LinkedMesh {

  final String parent;
  final String skin;
  final int slotIndex;
  final MeshAttachment mesh;

  _LinkedMesh(this.mesh, this.skin, this.slotIndex, this.parent);
}
