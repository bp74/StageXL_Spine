part of stagexl_spine;

class SkeletonDisplayObject extends DisplayObject {

  final Skeleton skeleton;
  final Matrix _skeletonMatrix = new Matrix(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
  final Matrix _identityMatrix = new Matrix.fromIdentity();

  SkeletonDisplayObject(SkeletonData skeletonData)
      : skeleton = new Skeleton(skeletonData) {

    skeleton.updateWorldTransform();
    skeleton.updateRenderGeometry();
  }

  //---------------------------------------------------------------------------

  @override
  Rectangle<num> get bounds {

    double minX = double.INFINITY;
    double minY = double.INFINITY;
    double maxX = double.NEGATIVE_INFINITY;
    double maxY = double.NEGATIVE_INFINITY;

    for (var slot in skeleton.drawOrder) {
      var attachment = slot.attachment;
      if (attachment is RenderAttachment) {
        var renderAttachment = attachment as RenderAttachment;
        var vxCount = renderAttachment.hullLength >> 1;
        var vxList = renderAttachment.vxList;
        for(int i = 0; i < vxCount; i++) {
          double x = vxList[i * 4 + 0];
          double y = vxList[i * 4 + 1];
          if (minX > x) minX = x;
          if (minY > y) minY = y;
          if (maxX < x) maxX = x;
          if (maxY < y) maxY = y;
        }
      }
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
      if (attachment is RenderAttachment) {
        var renderAttachment = attachment as RenderAttachment;
        var ixList = renderAttachment.ixList;
        var vxList = renderAttachment.vxList;
        var r = renderAttachment.r * skeletonR * slot.r;
        var g = renderAttachment.g * skeletonG * slot.g;
        var b = renderAttachment.b * skeletonB * slot.b;
        var a = renderAttachment.a * skeletonA * slot.a;
        var renderTexture = renderAttachment.bitmapData.renderTexture;
        renderContext.activateRenderTexture(renderTexture);
        renderContext.activateBlendMode(slot.data.blendMode);
        renderProgram.renderTextureMesh(renderState, ixList, vxList, r, g, b, a);
      }
    }

    renderState.pop();
  }

  //---------------------------------------------------------------------------

  void _renderCanvas(RenderState renderState) {

    var tmpMatrix = new Matrix.fromIdentity();

    renderState.push(_skeletonMatrix, skeleton.a, renderState.globalBlendMode);

    for (var slot in skeleton.drawOrder) {
      var attachment = slot.attachment;
      if (attachment is RegionAttachment) {
        var b = slot.bone;
        tmpMatrix.setTo(b.a, b.c, b.b, b.d, b.worldX, b.worldY);
        tmpMatrix.prepend(attachment.transformationMatrix);
        renderState.push(tmpMatrix, attachment.a * slot.a, slot.data.blendMode);
        renderState.renderTextureQuad(attachment.bitmapData.renderTextureQuad);
        renderState.pop();
      } else if (attachment is RenderAttachment) {
        var renderAttachment = attachment as RenderAttachment;
        var ixList = renderAttachment.ixList;
        var vxList = renderAttachment.vxList;
        var alpha = renderAttachment.a * slot.a;
        var renderTexture = renderAttachment.bitmapData.renderTexture;
        renderState.push(_identityMatrix, alpha, slot.data.blendMode);
        renderState.renderTextureMesh(renderTexture, ixList, vxList);
        renderState.pop();
      }
    }

    renderState.pop();
  }

}
