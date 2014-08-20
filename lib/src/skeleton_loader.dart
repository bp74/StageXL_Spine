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

class SkeletonLoader {

  static const String TIMELINE_SCALE = "scale";
  static const String TIMELINE_ROTATE = "rotate";
  static const String TIMELINE_TRANSLATE = "translate";
  static const String TIMELINE_ATTACHMENT = "attachment";
  static const String TIMELINE_COLOR = "color";

  final AttachmentLoader attachmentLoader;
  final num scale;

  SkeletonLoader(this.attachmentLoader, {this.scale: 1.0});

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

    // Bones.

    BoneData boneData;

    for (Map boneMap in root["bones"]) {

      BoneData parent = null;

      if (boneMap.containsKey("parent")) {
        String parentName = boneMap["parent"];
        parent = skeletonData.findBone(parentName);
        if (parent == null) throw new StateError("Parent bone not found: $parentName");
      }

      boneData = new BoneData(boneMap["name"], parent);
      boneData.length = (boneMap.containsKey("length") ? boneMap["length"] : 0) * scale;
      boneData.x = (boneMap.containsKey("x") ? boneMap["x"] : 0) * scale;
      boneData.y = (boneMap.containsKey("y") ? boneMap["y"] : 0) * scale;
      boneData.rotation = (boneMap.containsKey("rotation") ? boneMap["rotation"] : 0);
      boneData.scaleX = boneMap.containsKey("scaleX") ? boneMap["scaleX"] : 1;
      boneData.scaleY = boneMap.containsKey("scaleY") ? boneMap["scaleY"] : 1;
      boneData.inheritScale = boneMap.containsKey("inheritScale") ? boneMap["inheritScale"] : true;
      boneData.inheritRotation = boneMap.containsKey("inheritRotation") ? boneMap["inheritRotation"] : true;
      skeletonData.addBone(boneData);
    }

    // Slots.

    for (Map slotMap in root["slots"]) {

      String boneName = slotMap["bone"];

      boneData = skeletonData.findBone(boneName);
      if (boneData == null) throw new StateError("Slot bone not found: $boneName");
      SlotData slotData = new SlotData(slotMap["name"], boneData);

      if (slotMap.containsKey("color")) {
        String color = slotMap["color"];
        slotData.r = _toColor(color, 0);
        slotData.g = _toColor(color, 1);
        slotData.b = _toColor(color, 2);
        slotData.a = _toColor(color, 3);
      }

      slotData.attachmentName = slotMap["attachment"];
      slotData.additiveBlending = slotMap.containsKey("additive") ? slotMap["additive"] : false;

      skeletonData.addSlot(slotData);
    }

    // Skins.

    Map skins = root["skins"];

    for (String skinName in skins.keys) {
      Map skinMap = skins[skinName];
      Skin skin = new Skin(skinName);
      for (String slotName in skinMap.keys) {
        int slotIndex = skeletonData.findSlotIndex(slotName);
        Map slotEntry = skinMap[slotName];
        for (String attachmentName in slotEntry.keys) {
          Attachment attachment = readAttachment(skin, attachmentName, slotEntry[attachmentName]);
          if (attachment != null) skin.addAttachment(slotIndex, attachmentName, attachment);
        }
      }
      skeletonData.addSkin(skin);
      if (skin.name == "default") skeletonData.defaultSkin = skin;
    }

    // Events.
    if (root.containsKey("events")) {
      Map events = root["events"];
      for (String eventName in events.keys) {
        Map eventMap = events[eventName];
        EventData eventData = new EventData(eventName);
        eventData.intValue = eventMap.containsKey("int") ? eventMap["int"] : 0;
        eventData.floatValue = eventMap.containsKey("float") ? eventMap["float"] : 0.0;
        eventData.stringValue = eventMap.containsKey("string") ? eventMap["string"] : null;
        skeletonData.addEvent(eventData);
      }
    }

    // Animations.
    Map animations = root["animations"];
    for (String animationName in animations.keys) {
      readAnimation(animationName, animations[animationName], skeletonData);
    }

    return skeletonData;
  }

  Attachment readAttachment(Skin skin, String name, Map map) {

    name = map.containsKey("name") ? map["name"] : name;

    String typeName = map.containsKey("type") ? map["type"] : "region";
    AttachmentType type = AttachmentType.get(typeName);
    String path = map.containsKey("path") ? map["path"] : name;
    num scale = this.scale;

    switch (type) {

      case AttachmentType.region:

        RegionAttachment region = attachmentLoader.newRegionAttachment(skin, name, path);
        if (region == null) return null;

        region.path = path;
        region.x = (map.containsKey("x") ? map["x"] : 0) * scale;
        region.y = (map.containsKey("y") ? map["y"] : 0) * scale;
        region.scaleX = map.containsKey("scaleX") ? map["scaleX"] : 1;
        region.scaleY = map.containsKey("scaleY") ? map["scaleY"] : 1;
        region.rotation = map.containsKey("rotation") ? map["rotation"] : 0;
        region.width = (map.containsKey("width") ? map["width"] : 0) * scale;
        region.height = (map.containsKey("height") ? map["height"] : 0) * scale;

        if (map.containsKey("color")) {
          String color = map["color"];
          region.r = _toColor(color, 0);
          region.g = _toColor(color, 1);
          region.b = _toColor(color, 2);
          region.a = _toColor(color, 3);
        }

        region.updateUVs();
        region.updateOffset();
        return region;

      case AttachmentType.mesh:

        MeshAttachment mesh = attachmentLoader.newMeshAttachment(skin, name, path);
        if (mesh == null) return null;
        mesh.path = path;
        mesh.vertices = _getFloat32List(map, "vertices", scale);
        mesh.triangles = _getInt16List(map, "triangles");
        mesh.regionUVs = _getFloat32List(map, "uvs", 1.0);
        mesh.updateUVs();

        if (map.containsKey("color")) {
          String color = map["color"];
          mesh.r = _toColor(color, 0);
          mesh.g = _toColor(color, 1);
          mesh.b = _toColor(color, 2);
          mesh.a = _toColor(color, 3);
        }

        mesh.hullLength = (map.containsKey("hull") ? map["hull"] : 0) * 2;
        if (map.containsKey("edges")) mesh.edges = _getInt16List(map, "edges");
        mesh.width = (map.containsKey("width") ? map["width"] : 0) * scale;
        mesh.height = (map.containsKey("height") ? map["height"] : 0) * scale;
        return mesh;

      case AttachmentType.skinnedmesh:

        SkinnedMeshAttachment skinnedMesh = attachmentLoader.newSkinnedMeshAttachment(skin, name, path);
        if (skinnedMesh == null) return null;
        skinnedMesh.path = path;

        Float32List uvs = _getFloat32List(map, "uvs", 1);
        Float32List vertices = _getFloat32List(map, "vertices", 1);
        List<double> weights = new List<double>();
        List<int> bones = new List<int>();

        for (int i = 0; i < vertices.length; ) {
          int boneCount = vertices[i++].toInt();
          bones.add(boneCount);
          for (int nn = i + boneCount * 4; i < nn; ) {
            bones.add(vertices[i].toInt());
            weights.add(vertices[i + 1] * scale);
            weights.add(vertices[i + 2] * scale);
            weights.add(vertices[i + 3]);
            i += 4;
          }
        }

        skinnedMesh.bones = new Int16List.fromList(bones);
        skinnedMesh.weights = new Float32List.fromList(weights);
        skinnedMesh.triangles = _getInt16List(map, "triangles");
        skinnedMesh.regionUVs = uvs;
        skinnedMesh.updateUVs();

        if (map.containsKey("color")) {
          String color = map["color"];
          skinnedMesh.r = _toColor(color, 0);
          skinnedMesh.g = _toColor(color, 1);
          skinnedMesh.b = _toColor(color, 2);
          skinnedMesh.a = _toColor(color, 3);
        }

        skinnedMesh.hullLength = (map.containsKey("hull") ? map["hull"] : 0) * 2;
        if (map.containsKey("edges")) skinnedMesh.edges = _getInt16List(map, "edges");
        skinnedMesh.width = (map.containsKey("width") ? map["width"] : 0) * scale;
        skinnedMesh.height = (map.containsKey("height") ? map["height"] : 0) * scale;
        return skinnedMesh;

      case AttachmentType.boundingbox:

        BoundingBoxAttachment box = attachmentLoader.newBoundingBoxAttachment(skin, name);
        box.vertices = _getFloat32List(map, "vertices", scale);
        return box;
    }

    return null;
  }

  void readAnimation(String name, Map map, SkeletonData skeletonData) {

    List<Timeline> timelines = new List<Timeline>();
    num duration = 0;

    //-------------------------------------

    Map slots = map["slots"];
    if (slots == null) slots = const {};

    for (String slotName in slots.keys) {

      Map slotMap = slots[slotName];
      int slotIndex = skeletonData.findSlotIndex(slotName);

      for (String timelineName in slotMap.keys) {

        List values = slotMap[timelineName];

        if (timelineName == TIMELINE_COLOR) {

          ColorTimeline colorTimeline = new ColorTimeline(values.length);
          colorTimeline.slotIndex = slotIndex;

          int frameIndex = 0;
          for (Map valueMap in values) {
            String color = valueMap["color"];
            num r = _toColor(color, 0);
            num g = _toColor(color, 1);
            num b = _toColor(color, 2);
            num a = _toColor(color, 3);
            colorTimeline.setFrame(frameIndex, valueMap["time"], r, g, b, a);
            _readCurve(colorTimeline, frameIndex, valueMap);
            frameIndex++;
          }

          timelines.add(colorTimeline);
          duration = math.max(duration, colorTimeline.frames[colorTimeline.frameCount * 5 - 5]);

        } else if (timelineName == TIMELINE_ATTACHMENT) {

          AttachmentTimeline attachmentTimeline = new AttachmentTimeline(values.length);
          attachmentTimeline.slotIndex = slotIndex;

          int frameIndex = 0;
          for (Map valueMap in values) {
            attachmentTimeline.setFrame(frameIndex++, valueMap["time"], valueMap["name"]);
          }

          timelines.add(attachmentTimeline);
          duration = math.max(duration, attachmentTimeline.frames[attachmentTimeline.frameCount - 1]);

        } else {

          throw new StateError("Invalid timeline type for a slot: $timelineName ($slotName)");

        }
      }
    }

    //-------------------------------------

    Map bones = map["bones"];
    if (bones == null) bones = const {};

    for (String boneName in bones.keys) {

      int boneIndex = skeletonData.findBoneIndex(boneName);
      if (boneIndex == -1) throw new StateError("Bone not found: $boneName");

      Map boneMap = bones[boneName];

      for (String timelineName in boneMap.keys) {

        List values = boneMap[timelineName];

        if (timelineName == TIMELINE_ROTATE) {

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

        } else if (timelineName == TIMELINE_TRANSLATE || timelineName == TIMELINE_SCALE) {

          TranslateTimeline timeline;
          num timelineScale = 1;

          if (timelineName == TIMELINE_SCALE) {
            timeline = new ScaleTimeline(values.length);
          } else {
            timeline = new TranslateTimeline(values.length);
            timelineScale = scale;
          }

          timeline.boneIndex = boneIndex;

          int frameIndex = 0;
          for (Map valueMap in values) {
            num x = (valueMap.containsKey("x") ? valueMap["x"] : 0) * timelineScale;
            num y = (valueMap.containsKey("y") ? valueMap["y"] : 0) * timelineScale;
            timeline.setFrame(frameIndex, valueMap["time"], x, y);
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

    Map ffd = map["ffd"];
    if (ffd == null) ffd = const {};

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

          int vertexCount;
          if (attachment is MeshAttachment) {
            var meshAttachment = attachment;
            vertexCount = meshAttachment.vertices.length;
          } else if (attachment is SkinnedMeshAttachment) {
            var skinnedMeshAttachment = attachment;
            vertexCount = skinnedMeshAttachment.weights.length ~/ 3 * 2;
          } else {
            throw new StateError("Invalid attachment.");
          }

          int frameIndex = 0;
          for (Map valueMap in values) {
            Float32List vertices;
            if (valueMap.containsKey("vertices") == false) {
              if (attachment is MeshAttachment) {
                var meshAttachment = attachment;
                vertices = meshAttachment.vertices;
              } else {
                vertices = new Float32List(vertexCount);
              }
            } else {
              Float32List verticesValue = _getFloat32List(valueMap, "vertices", scale);
              int start = valueMap.containsKey("offset") ? valueMap["offset"] : 0;
              vertices = new Float32List(vertexCount);
              for (int i = 0; i < verticesValue.length; i++) {
                vertices[i + start] = verticesValue[i];
              }
              if (attachment is MeshAttachment) {
                var meshAttachment = attachment;
                var meshVertices = meshAttachment.vertices;
                for (int i = 0; i < vertexCount; i++) {
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

    List drawOrderValues = map["draworder"];
    if (drawOrderValues != null) {

      DrawOrderTimeline drawOrderTimeline = new DrawOrderTimeline(drawOrderValues.length);
      int slotCount = skeletonData.slots.length;
      int frameIndex = 0;

      for (Map drawOrderMap in drawOrderValues) {

        Int16List drawOrder = null;

        if (drawOrderMap.containsKey("offsets")) {

          drawOrder = new Int16List(slotCount);
          for(int i = 0; i < drawOrder.length; i++) {
            drawOrder[i] = -1;
          }

          List offsets = drawOrderMap["offsets"];
          Int16List unchanged = new Int16List(slotCount - offsets.length);
          int originalIndex = 0;
          int unchangedIndex = 0;

          for (Map offsetMap in offsets) {
            int slotIndex = skeletonData.findSlotIndex(offsetMap["slot"]);
            if (slotIndex == -1) throw new StateError("Slot not found: ${offsetMap["slot"]}");
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

        drawOrderTimeline.setFrame(frameIndex++, drawOrderMap["time"], drawOrder);
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

        EventData eventData = skeletonData.findEvent(eventMap["name"]);
        if (eventData == null) throw new StateError("Event not found: ${eventMap["name"]}");

        Event event = new Event(eventData);
        event.intValue = eventMap.containsKey("int") ? eventMap["int"] : eventData.intValue;
        event.floatValue = eventMap.containsKey("float") ? eventMap["float"] : eventData.floatValue;
        event.stringValue = eventMap.containsKey("string") ? eventMap["string"] : eventData.stringValue;
        eventTimeline.setFrame(frameIndex++, eventMap["time"], event);
      }

      timelines.add(eventTimeline);
      duration = math.max(duration, eventTimeline.frames[eventTimeline.frameCount - 1]);
    }

    skeletonData.addAnimation(new Animation(name, timelines, duration));
  }

  //-----------------------------------------------------------------------------------------------
  //-----------------------------------------------------------------------------------------------

  void _readCurve(CurveTimeline timeline, int frameIndex, Map valueMap) {
    if (valueMap.containsKey("curve") == false) return;
    var curve = valueMap["curve"];
    if (curve == "stepped") {
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

  Float32List _getFloat32List(Map map, String name, num scale) {
    List values = map[name];
    Float32List result = new Float32List(values.length);
    for (int i = 0; i < values.length; i++) {
      result[i] = values[i].toDouble() * scale;
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

}
