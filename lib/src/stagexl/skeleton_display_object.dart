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
      if (attachment is _RenderAttachment) {
        var renderAttachment = attachment as _RenderAttachment;
        var oxList = renderAttachment.oxList;
        var vxList = renderAttachment.vxList;
        for(int i = 0; i < oxList.length; i++) {
          int offset = oxList[i] * 4;
          double x = vxList[offset + 0];
          double y = vxList[offset + 1];
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
      if (attachment is _RenderAttachment) {
        var renderAttachment = attachment as _RenderAttachment;
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
    var boneMatrix = new Matrix.fromIdentity();
    var skeletonA = skeleton.a;

    renderState.push(_skeletonMatrix, 1.0, renderState.globalBlendMode);

    for (var slot in skeleton.drawOrder) {
      var attachment = slot.attachment;
      if (attachment is RegionAttachment) {
        var bitmapData = attachment.bitmapData;
        var blendMode = slot.data.blendMode;
        var alpha = skeletonA * attachment.a * slot.a;
        var bone = slot.bone;
        boneMatrix.setTo(bone.a, bone.c, bone.b, bone.d, bone.worldX, bone.worldY);
        tmpMatrix.copyFrom(attachment.transformationMatrix);
        tmpMatrix.concat(boneMatrix);
        renderState.push(tmpMatrix, alpha, blendMode);
        renderState.renderTextureQuad(bitmapData.renderTextureQuad);
        renderState.pop();
      } else if (attachment is _RenderAttachment) {
        var renderAttachment = attachment as _RenderAttachment;
        var bitmapData = renderAttachment.bitmapData;
        var renderTexture = bitmapData.renderTexture;
        var blendMode = slot.data.blendMode;
        var ixList = renderAttachment.ixList;
        var vxList = renderAttachment.vxList;
        var alpha = skeletonA * renderAttachment.a * slot.a;
        renderState.push(_identityMatrix, alpha, blendMode);
        renderState.renderTextureMesh(renderTexture, ixList, vxList);
        renderState.pop();
      }
    }

    renderState.pop();
  }

}
