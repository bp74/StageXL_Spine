part of stagexl_spine;

enum SkeletonBoundsCalculation { None, BoundingBoxes, Hull }

class SkeletonDisplayObject extends DisplayObject {

  final Skeleton skeleton;
  final Matrix _skeletonMatrix = new Matrix(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
  final Matrix _identityMatrix = new Matrix.fromIdentity();
  final Matrix _transformMatrix = new Matrix.fromIdentity();

  static final Float32List _boundsVertices = new Float32List(2048);

  SkeletonBoundsCalculation boundsCalculation = SkeletonBoundsCalculation.None;

  SkeletonDisplayObject(SkeletonData skeletonData)
      : skeleton = new Skeleton(skeletonData) {

    skeleton.updateWorldTransform();
  }

  //---------------------------------------------------------------------------

  @override
  Rectangle<num> get bounds {

    Float32List vertices = _boundsVertices;
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
        if (attachment is RenderableAttachment) {
          var renderable = attachment as RenderableAttachment;
          var length = renderable.hullLength;
          renderable.computeWorldVertices2(slot, 0, length, vertices, offset, 2);
          offset += length;
        }
      }
    }

    double minX = double.INFINITY;
    double minY = double.INFINITY;
    double maxX = double.NEGATIVE_INFINITY;
    double maxY = double.NEGATIVE_INFINITY;

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

    return new Rectangle<num>(minX, 0.0 - maxY, maxX - minX, maxY - minY);
  }

  @override
  DisplayObject hitTestInput(num localX, num localY) {
    return bounds.contains(localX, localY) ? this : null;
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
    var skeletonR = skeleton.r;
    var skeletonG = skeleton.g;
    var skeletonB = skeleton.b;
    var skeletonA = skeleton.a;

    renderContext.activateRenderProgram(renderProgram);
    renderState.push(_skeletonMatrix, 1.0, renderState.globalBlendMode);

    for (var slot in skeleton.drawOrder) {
      var attachment = slot.attachment;
      if (attachment is RenderableAttachment) {
        var renderable = attachment as RenderableAttachment;
        renderable.updateRenderGeometry(slot);
        var ixList = renderable.ixList;
        var vxList = renderable.vxList;
        var r = renderable.r * skeletonR * slot.r;
        var g = renderable.g * skeletonG * slot.g;
        var b = renderable.b * skeletonB * slot.b;
        var a = renderable.a * skeletonA * slot.a;
        var renderTexture = renderable.bitmapData.renderTexture;
        renderContext.activateRenderTexture(renderTexture);
        renderContext.activateBlendMode(slot.data.blendMode);
        renderProgram.renderTextureMesh(renderState, ixList, vxList, r, g, b, a);
      }
    }

    renderState.pop();
  }

  //---------------------------------------------------------------------------

  void _renderCanvas(RenderState renderState) {

    Matrix transform = _transformMatrix;
    renderState.push(_skeletonMatrix, skeleton.a, renderState.globalBlendMode);

    for (var slot in skeleton.drawOrder) {
      var attachment = slot.attachment;
      if (attachment is RegionAttachment) {
        var b = slot.bone;
        transform.setTo(b.a, b.c, b.b, b.d, b.worldX, b.worldY);
        transform.prepend(attachment.transformationMatrix);
        renderState.push(transform, attachment.a * slot.a, slot.data.blendMode);
        renderState.renderTextureQuad(attachment.bitmapData.renderTextureQuad);
        renderState.pop();
      } else if (attachment is RenderableAttachment) {
        var renderable = attachment as RenderableAttachment;
        renderable.updateRenderGeometry(slot);
        var ixList = renderable.ixList;
        var vxList = renderable.vxList;
        var alpha = renderable.a * slot.a;
        var renderTexture = renderable.bitmapData.renderTexture;
        renderState.push(_identityMatrix, alpha, slot.data.blendMode);
        renderState.renderTextureMesh(renderTexture, ixList, vxList);
        renderState.pop();
      }
    }

    renderState.pop();
  }

}
