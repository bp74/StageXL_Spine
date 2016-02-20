part of stagexl_spine;

class SkeletonDisplayObject extends DisplayObject {

  final Skeleton skeleton;

  SkeletonDisplayObject(SkeletonData skeletonData)
      : skeleton = new Skeleton(skeletonData) {

    skeleton.updateWorldTransform();
  }

  //---------------------------------------------------------------------------

  @override
  Rectangle<num> get bounds {
    // TODO: Currently bounds are not supported.
    // We sould add an opt-in flag.
    return new Rectangle<num>(0.0, 0.0, 0.0, 0.0);
  }

  @override
  DisplayObject hitTestInput(num localX, num localY) {
    // TODO: Currently hitTests are not supported.
    // We sould add an opt-in flag.
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
    renderContext.activateRenderProgram(renderProgram);

    var skeletonX = skeleton.x;
    var skeletonY = skeleton.y;
    var skeletonR = skeleton.r;
    var skeletonG = skeleton.g;
    var skeletonB = skeleton.b;
    var skeletonA = skeleton.a;

    for (var slot in skeleton.drawOrder) {
      var attachment = slot.attachment;
      if (attachment is _RenderAttachment) {
        var ixList = attachment.ixList;
        var vxList = attachment.getVertexList(skeletonX, skeletonY, slot);
        var renderTexture = attachment.bitmapData.renderTexture;
        var r = attachment.r * skeletonR * slot.r;
        var g = attachment.g * skeletonG * slot.g;
        var b = attachment.b * skeletonB * slot.b;
        var a = attachment.a * skeletonA * slot.a;
        renderContext.activateRenderTexture(renderTexture);
        renderContext.activateBlendMode(slot.data.blendMode);
        renderProgram.renderTextureMesh(renderState, ixList, vxList, r, g, b, a);
      }
    }
  }

  //---------------------------------------------------------------------------

  void _renderCanvas(RenderState renderState) {

    var renderContext = renderState.renderContext;
    var globalMatrix = renderState.globalMatrix;
    var globalAlpha = renderState.globalAlpha;
    var tmpMatrix = new Matrix.fromIdentity();
    var tmpRenderState = new RenderState(renderContext);
    var boneMatrix = new Matrix.fromIdentity();

    var skeletonX = skeleton.x;
    var skeletonY = skeleton.y;
    var skeletonA = skeleton.a;

    for (var slot in skeleton.drawOrder) {
      var attachment = slot.attachment;
      if (attachment is RegionAttachment) {
        var bitmapData = attachment.bitmapData;
        var blendMode = slot.data.blendMode;
        var alpha = globalAlpha * skeletonA * attachment.a * slot.a;
        var b = slot.bone;
        boneMatrix.setTo(b.a, 0.0 - b.c, b.b, 0 - b.d, b.worldX, 0 - b.worldY);
        tmpMatrix.copyFrom(attachment.matrix);
        tmpMatrix.translate(skeletonX, skeletonY);
        tmpMatrix.concat(boneMatrix);
        tmpMatrix.concat(globalMatrix);
        tmpRenderState.reset(tmpMatrix, alpha, blendMode);
        tmpRenderState.renderTextureQuad(bitmapData.renderTextureQuad);
      } else if (attachment is _RenderAttachment) {
        var bitmapData = attachment.bitmapData;
        var renderTexture = bitmapData.renderTexture;
        var blendMode = slot.data.blendMode;
        var ixList = attachment.ixList;
        var vxList = attachment.getVertexList(skeletonX, skeletonY, slot);
        var alpha = globalAlpha * skeletonA * attachment.a * slot.a;
        tmpRenderState.reset(globalMatrix, alpha, blendMode);
        tmpRenderState.renderTextureMesh(renderTexture, ixList, vxList);
      }
    }
  }

}
