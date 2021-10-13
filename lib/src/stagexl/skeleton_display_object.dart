part of stagexl_spine;

enum SkeletonBoundsCalculation { None, BoundingBoxes, Hull }

class SkeletonDisplayObject extends DisplayObject {
  final Skeleton skeleton;
  final Matrix _skeletonMatrix = Matrix(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
  final Matrix _identityMatrix = Matrix.fromIdentity();
  final Matrix _transformMatrix = Matrix.fromIdentity();

  static final Float32List _vertices = Float32List(2048);
  static final SkeletonClipping _clipping = SkeletonClipping();

  SkeletonBoundsCalculation boundsCalculation = SkeletonBoundsCalculation.None;

  SkeletonDisplayObject(SkeletonData skeletonData) : skeleton = Skeleton(skeletonData) {
    skeleton.updateWorldTransform();
  }

  //---------------------------------------------------------------------------

  @override
  Rectangle<num> get bounds {
    Float32List vertices = _vertices;
    int offset = 0;

    if (boundsCalculation == SkeletonBoundsCalculation.BoundingBoxes) {
      for (var slot in skeleton.drawOrder) {
        var attachment = slot.attachment;
        if (attachment is BoundingBoxAttachment) {
          var length = attachment.worldVerticesLength;
          attachment.computeWorldVertices2(slot, 0, length, vertices, offset, 2);
          offset += length;
        }
      }
    } else if (boundsCalculation == SkeletonBoundsCalculation.Hull) {
      for (var slot in skeleton.drawOrder) {
        var attachment = slot.attachment;
        if (attachment is RenderAttachment) {
          var length = attachment.hullLength;
          attachment.computeWorldVertices2(slot, 0, length, vertices, offset, 2);
          offset += length;
        }
      }
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < offset - 1; i += 2) {
      double x = vertices[i + 0];
      double y = vertices[i + 1];
      if (minX > x) minX = x;
      if (minY > y) minY = y;
      if (maxX < x) maxX = x;
      if (maxY < y) maxY = y;
    }

    minX = minX.isFinite ? minX : 0.0;
    minY = minY.isFinite ? minY : 0.0;
    maxX = maxX.isFinite ? maxX : 0.0;
    maxY = maxY.isFinite ? maxY : 0.0;

    return Rectangle<num>(minX, 0.0 - maxY, maxX - minX, maxY - minY);
  }

  @override
  DisplayObject? hitTestInput(num localX, num localY) {
    Float32List vertices = _vertices;
    double sx = 0.0 + localX;
    double sy = 0.0 - localY;

    if (boundsCalculation == SkeletonBoundsCalculation.BoundingBoxes) {
      for (var slot in skeleton.drawOrder) {
        var attachment = slot.attachment;
        if (attachment is BoundingBoxAttachment) {
          var length = attachment.worldVerticesLength;
          attachment.computeWorldVertices2(slot, 0, length, vertices, 0, 2);
          if (_windingCount(vertices, length, sx, sy) != 0) return this;
        }
      }
    } else if (boundsCalculation == SkeletonBoundsCalculation.Hull) {
      for (var slot in skeleton.drawOrder) {
        var attachment = slot.attachment;
        if (attachment is RenderAttachment) {
          var length = attachment.hullLength;
          attachment.computeWorldVertices2(slot, 0, length, vertices, 0, 2);
          if (_windingCount(vertices, length, sx, sy) != 0) return this;
        }
      }
    }

    return null;
  }

  @override
  void render(RenderState renderState) {
    var renderContext = renderState.renderContext;
    if (renderContext is RenderContextWebGL) {
      _renderWebGL(renderState);
    } else {
      _renderCanvas(renderState);
    }
  }

  //---------------------------------------------------------------------------

  void _renderWebGL(RenderState renderState) {
    var renderContext = renderState.renderContext as RenderContextWebGL;
    var renderProgram = renderContext.renderProgramTinted;
    var skeletonR = skeleton.color.r;
    var skeletonG = skeleton.color.g;
    var skeletonB = skeleton.color.b;
    var skeletonA = skeleton.color.a;
    var slots = skeleton.drawOrder;
    var vertices = _vertices;
    var clipping = _clipping;

    ClippingAttachment? clippingAttachment;
    renderContext.activateRenderProgram(renderProgram);
    renderState.push(_skeletonMatrix, 1.0, renderState.globalBlendMode);

    for (int s = 0; s < slots.length; s++) {
      var slot = slots[s];
      var attachment = slot.attachment;

      if (attachment is RenderAttachment) {
        attachment.updateRenderGeometry(slot);
        renderContext.activateRenderTexture(attachment.bitmapData.renderTexture);
        renderContext.activateBlendMode(slot.data.blendMode);
        renderProgram.renderTextureMesh(
            renderState,
            attachment.ixList,
            attachment.vxList,
            attachment.color.r * skeletonR * slot.color.r,
            attachment.color.g * skeletonG * slot.color.g,
            attachment.color.b * skeletonB * slot.color.b,
            attachment.color.a * skeletonA * slot.color.a);
      } else if (attachment is ClippingAttachment) {
        var length = attachment.worldVerticesLength;
        attachment.computeWorldVertices2(slot, 0, length, vertices, 0, 2);
        clipping.vertices = vertices.buffer.asFloat32List(0, length);
        renderContext.beginRenderMask(renderState, clipping);
        renderContext.activateRenderProgram(renderProgram);
        clippingAttachment = attachment;
      }

      if (clippingAttachment != null) {
        if (s == slots.length - 1 || clippingAttachment.endSlot == slot.data) {
          renderContext.endRenderMask(renderState, clipping);
          renderContext.activateRenderProgram(renderProgram);
          clippingAttachment = null;
        }
      }
    }

    renderState.pop();
  }

  void _renderCanvas(RenderState renderState) {
    var renderContext = renderState.renderContext as RenderContextCanvas;
    var vertices = _vertices;
    var clipping = _clipping;
    var transform = _transformMatrix;
    var slots = skeleton.drawOrder;

    ClippingAttachment? clippingAttachment;
    renderState.push(_skeletonMatrix, skeleton.color.a, renderState.globalBlendMode);

    for (int s = 0; s < slots.length; s++) {
      var slot = slots[s];
      var attachment = slot.attachment;

      if (attachment is RegionAttachment) {
        var b = slot.bone;
        transform.setTo(b.a, b.c, b.b, b.d, b.worldX, b.worldY);
        transform.prepend(attachment.transformationMatrix);
        renderState.push(transform, attachment.color.a * slot.color.a, slot.data.blendMode);
        renderState.renderTextureQuad(attachment.bitmapData.renderTextureQuad);
        renderState.pop();
      } else if (attachment is RenderAttachment) {
        attachment.updateRenderGeometry(slot);
        var ixList = attachment.ixList;
        var vxList = attachment.vxList;
        var alpha = attachment.color.a * slot.color.a;
        var renderTexture = attachment.bitmapData.renderTexture;
        renderState.push(_identityMatrix, alpha, slot.data.blendMode);
        renderState.renderTextureMesh(renderTexture, ixList, vxList);
        renderState.pop();
      } else if (attachment is ClippingAttachment) {
        var length = attachment.worldVerticesLength;
        attachment.computeWorldVertices2(slot, 0, length, vertices, 0, 2);
        clipping.vertices = vertices.buffer.asFloat32List(0, length);
        renderContext.beginRenderMask(renderState, clipping);
        clippingAttachment = attachment;
      }

      if (clippingAttachment != null) {
        if (s == slots.length - 1 || clippingAttachment.endSlot == slot.data) {
          renderContext.endRenderMask(renderState, clipping);
          clippingAttachment = null;
        }
      }
    }

    renderState.pop();
  }

  //---------------------------------------------------------------------------

  int _windingCount(Float32List vertices, int length, double x, double y) {
    double ax = vertices[length - 2];
    double ay = vertices[length - 1];
    int wn = 0;

    for (int i = 0; i < length - 1; i += 2) {
      double bx = vertices[i + 0];
      double by = vertices[i + 1];
      if (ay <= y) {
        if (by > y && (bx - ax) * (y - ay) - (x - ax) * (by - ay) > 0) wn++;
      } else {
        if (by <= y && (bx - ax) * (y - ay) - (x - ax) * (by - ay) < 0) wn--;
      }
      ax = bx;
      ay = by;
    }

    return wn;
  }
}
