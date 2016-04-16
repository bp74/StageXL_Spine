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
    }

    // Bones

    for (Map boneMap in root["bones"] ?? []) {

      BoneData parent = null;

      String parentName = _getString(boneMap, "parent", null);
      if (parentName != null) {
        parent = skeletonData.findBone(parentName);
        if (parent == null) throw new StateError("Parent bone not found: $parentName");
      }

      var boneData = new BoneData(_getString(boneMap, "name", null), parent);
      boneData.length = _getDouble(boneMap, "length", 0.0);
      boneData.x = _getDouble(boneMap, "x", 0.0);
      boneData.y = _getDouble(boneMap, "y", 0.0);
      boneData.rotation = _getDouble(boneMap, "rotation", 0.0);
      boneData.scaleX = _getDouble(boneMap, "scaleX", 1.0);
      boneData.scaleY = _getDouble(boneMap, "scaleY", 1.0);
      boneData.inheritScale = _getBool(boneMap, "inheritScale", true);
      boneData.inheritRotation = _getBool(boneMap, "inheritRotation", true);
      skeletonData.bones.add(boneData);
    }

    // IK constraints.

    for (Map ikMap in root["ik"] ?? []) {

      var ikConstraintData = new IkConstraintData(_getString(ikMap, "name", null));

      for (var boneName in ikMap["bones"]) {
        var bone = skeletonData.findBone(boneName);
        if (bone == null) throw new StateError("IK bone not found: " + boneName);
        ikConstraintData.bones.add(bone);
      }

      var targetName = _getString(ikMap, "target", null);
      var target = skeletonData.findBone(targetName);
      if (target == null) throw new StateError("Target bone not found: " + targetName);

      ikConstraintData.target = target;
      ikConstraintData.bendDirection = _getBool(ikMap, "bendPositive", true) ? 1 : -1;
      ikConstraintData.mix = _getDouble(ikMap, "mix", 1.0);

      skeletonData.ikConstraints.add(ikConstraintData);
    }

    // Transform constraints.

    for (Map transformMap in root["transform"] ?? []) {

      var transformConstraintData = new TransformConstraintData(_getString(transformMap, "name", null));

      var boneName = _getString(transformMap, "bone", null);
      var bone = skeletonData.findBone(boneName);
      if (bone == null) throw new StateError("Bone not found: " + boneName);

      var targetName = _getString(transformMap, "target", null);
      var target = skeletonData.findBone(targetName);
      if (target == null) throw new StateError("Target bone not found: " + targetName);

      transformConstraintData.bone = bone;
      transformConstraintData.target = target;
      transformConstraintData.translateMix = _getDouble(transformMap, "translateMix", 1.0);
      transformConstraintData.x = _getDouble(transformMap, "x", 0.0);
      transformConstraintData.y = _getDouble(transformMap, "y", 0.0);

      skeletonData.transformConstraints.add(transformConstraintData);
    }

    // Slots

    for (Map slotMap in root["slots"] ?? []) {

      var boneName = _getString(slotMap, "bone", null);
      var boneData = skeletonData.findBone(boneName);
      if (boneData == null) throw new StateError("Slot bone not found: $boneName");

      SlotData slotData = new SlotData(_getString(slotMap, "name", null), boneData);
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

    // Skins

    Map skins = root["skins"] ?? {};

    for (String skinName in skins.keys) {
      var skinMap = skins[skinName];
      var skin = new Skin(skinName);
      for (String slotName in skinMap.keys) {
        var slotIndex = skeletonData.findSlotIndex(slotName);
        var slotEntry = skinMap[slotName];
        for (String attachmentName in slotEntry.keys) {
          var attachment = readAttachment(skin, slotIndex, attachmentName, slotEntry[attachmentName]);
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
      if (linkedMesh.mesh is MeshAttachment) {
        MeshAttachment mesh = linkedMesh.mesh;
        mesh.parentMesh = parentMesh as MeshAttachment;
      } else {
        WeightedMeshAttachment weightedMesh  = linkedMesh.mesh;
        weightedMesh.parentMesh = parentMesh as WeightedMeshAttachment;
      }
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
      readAnimation(animationName, animations[animationName], skeletonData);
    }

    return skeletonData;
  }

  //---------------------------------------------------------------------------

  Attachment readAttachment(Skin skin, int slotIndex, String name, Map map) {

    name = _getString(map, "name", name);

    var typeName = _getString(map, "type", "region");
    var type = AttachmentType.get(typeName);
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

        if (map.containsKey("parent") == false) {
          var triangles = _getInt16List(map, "triangles");
          var vertices = _getFloat32List(map, "vertices");
          var uvs = _getFloat32List(map, "uvs");
          mesh.hullLength = _getInt(map, "hull", 0) * 2;
          mesh.edges = map.containsKey("edges") ? _getInt16List(map, "edges") : null;
          mesh.update(triangles, vertices, uvs);
        } else {
          var skin = _getString(map, "skin", null);
          var parent = _getString(map, "parent", null);
          var linkedMesh = new _LinkedMesh(mesh, skin, slotIndex, parent);
          mesh.inheritFFD = _getBool(map, "ffd", true);
          _linkedMeshes.add(linkedMesh);
        }

        return mesh;

      case AttachmentType.weightedmesh:
      case AttachmentType.weightedlinkedmesh:

        var weightedMesh = attachmentLoader.newWeightedMeshAttachment(skin, name, path);
        if (weightedMesh == null) return null;

        var weightedMeshColor = _getString(map, "color", "FFFFFFFF");
        weightedMesh.r = _toColor(weightedMeshColor, 0);
        weightedMesh.g = _toColor(weightedMeshColor, 1);
        weightedMesh.b = _toColor(weightedMeshColor, 2);
        weightedMesh.a = _toColor(weightedMeshColor, 3);
        weightedMesh.width = _getDouble(map, "width", 0.0);
        weightedMesh.height = _getDouble(map, "height", 0.0);

        if (map.containsKey("parent") == false) {
          var triangles = _getInt16List(map, "triangles");
          var vertices = _getFloat32List(map, "vertices");
          var uvs = _getFloat32List(map, "uvs");
          weightedMesh.hullLength = _getInt(map, "hull", 0) * 2;
          weightedMesh.edges = map.containsKey("edges") ? _getInt16List(map, "edges") : null;
          weightedMesh.update(triangles, vertices, uvs);
        } else {
          var skin = _getString(map, "skin", null);
          var parent = _getString(map, "parent", null);
          var linkedMesh = new _LinkedMesh(weightedMesh, skin, slotIndex, parent);
          weightedMesh.inheritFFD = _getBool(map, "ffd", true);
          _linkedMeshes.add(linkedMesh);
        }

        return weightedMesh;

      case AttachmentType.boundingbox:

        var box = attachmentLoader.newBoundingBoxAttachment(skin, name);
        if (box == null) return null;

        box.vertices = _getFloat32List(map, "vertices");
        return box;
    }

    return null;
  }

  //---------------------------------------------------------------------------

  void readAnimation(String name, Map map, SkeletonData skeletonData) {

    List<Timeline> timelines = new List<Timeline>();
    num duration = 0;

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
            num time = _getDouble(valueMap, "time", 0.0);
            String color = _getString(valueMap, "color", "FFFFFFFF");
            num r = _toColor(color, 0);
            num g = _toColor(color, 1);
            num b = _toColor(color, 2);
            num a = _toColor(color, 3);
            colorTimeline.setFrame(frameIndex, time, r, g, b, a);
            _readCurve(colorTimeline, frameIndex, valueMap);
            frameIndex++;
          }

          timelines.add(colorTimeline);
          duration = math.max(duration, colorTimeline.frames[colorTimeline.frameCount * 5 - 5]);

        } else if (timelineName == "attachment") {

          AttachmentTimeline attachmentTimeline = new AttachmentTimeline(values.length);
          attachmentTimeline.slotIndex = slotIndex;

          int frameIndex = 0;
          for (Map valueMap in values) {
            num time = _getDouble(valueMap, "time", 0.0);
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
            _readCurve(rotateTimeline, frameIndex, valueMap);
            frameIndex++;
          }

          timelines.add(rotateTimeline);
          duration = math.max(duration, rotateTimeline.frames[rotateTimeline.frameCount * 2 - 2]);

        } else if (timelineName == "translate" || timelineName == "scale") {

          TranslateTimeline timeline;

          if (timelineName == "scale") {
            timeline = new ScaleTimeline(values.length);
          } else {
            timeline = new TranslateTimeline(values.length);
          }

          timeline.boneIndex = boneIndex;

          int frameIndex = 0;
          for (Map valueMap in values) {
            num x = _getDouble(valueMap, "x", 0.0);
            num y = _getDouble(valueMap, "y", 0.0);
            num time = _getDouble(valueMap, "time", 0.0);
            timeline.setFrame(frameIndex, time, x, y);
            _readCurve(timeline, frameIndex, valueMap);
            frameIndex++;
          }

          timelines.add(timeline);
          duration = math.max(duration, timeline.frames[timeline.frameCount * 3 - 3]);

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
        num time = _getDouble(valueMap, "time", 0.0);
        num mix = _getDouble(valueMap, "mix", 1.0);
        int bendDirection = _getBool(valueMap, "bendPositive", true) ? 1 : -1;
        ikTimeline.setFrame(frameIndex, time, mix, bendDirection);
        _readCurve(ikTimeline, frameIndex, valueMap);
        frameIndex++;
      }
      timelines.add(ikTimeline);
      duration = math.max(duration, ikTimeline.frames[ikTimeline.frameCount * 3 - 3]);
    }

    //-------------------------------------

    Map ffd = map["ffd"] ?? {};

    for (String skinName in ffd.keys) {

      Skin skin = skeletonData.findSkin(skinName);
      Map slotMap = ffd[skinName];

      for (String slotName in slotMap.keys) {

        int slotIndex = skeletonData.findSlotIndex(slotName);

        Map meshMap = slotMap[slotName];
        for (String meshName in meshMap.keys) {

          List values = meshMap[meshName];

          FfdTimeline ffdTimeline = new FfdTimeline(values.length);
          Attachment attachment = skin.getAttachment(slotIndex, meshName);
          if (attachment == null) throw new StateError("FFD attachment not found: $meshName");
          ffdTimeline.slotIndex = slotIndex;
          ffdTimeline.attachment = attachment;

          int vertexLength;
          if (attachment is MeshAttachment) {
            vertexLength = attachment.vertexLength;
          } else if (attachment is WeightedMeshAttachment) {
            vertexLength = attachment.vertexLength;
          } else {
            throw new StateError("Invalid attachment.");
          }

          int frameIndex = 0;
          for (Map valueMap in values) {
            Float32List vertices;
            if (valueMap.containsKey("vertices") == false) {
              if (attachment is MeshAttachment) {
                vertices = attachment.vertices;
              } else {
                vertices = new Float32List(vertexLength);
              }
            } else {
              Float32List verticesValue = _getFloat32List(valueMap, "vertices");
              int start = _getInt(valueMap, "offset", 0);
              vertices = new Float32List(vertexLength);
              for (int i = 0; i < verticesValue.length; i++) {
                vertices[i + start] = verticesValue[i];
              }
              if (attachment is MeshAttachment) {
                var meshVertices = attachment.vertices;
                for (int i = 0; i < vertexLength; i++) {
                  vertices[i] += meshVertices[i];
                }
              }
            }

            ffdTimeline.setFrame(frameIndex, valueMap["time"], vertices);
            _readCurve(ffdTimeline, frameIndex, valueMap);
            frameIndex++;
          }

          timelines.add(ffdTimeline);
          duration = math.max(duration, ffdTimeline.frames[ffdTimeline.frameCount - 1]);
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

        num time = _getDouble(drawOrderMap, "time", 0.0);
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

  void _readCurve(CurveTimeline timeline, int frameIndex, Map valueMap) {
    var curve = valueMap["curve"];
    if (curve == null) {
      return;
    } else if (curve == "stepped") {
      timeline.setStepped(frameIndex);
    } else if (curve is List) {
      timeline.setCurve(frameIndex, curve[0], curve[1], curve[2], curve[3]);
    }
  }

  num _toColor(String hexString, int colorIndex) {
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
  final Attachment mesh;

  _LinkedMesh(this.mesh, this.skin, this.slotIndex, this.parent);
}
