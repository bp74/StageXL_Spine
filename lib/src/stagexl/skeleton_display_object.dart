part of stagexl_spine;

class SkeletonDisplayObject extends DisplayObject {

  final Skeleton skeleton;
  num timeScale = 1.0;

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

    RenderContext renderContext = renderState.renderContext;
    RenderContextWebGL renderContextWebGL = renderContext;
    RenderProgramTinted renderProgram = renderContextWebGL.renderProgramTinted;

    num skeletonX = skeleton.x;
    num skeletonY = skeleton.y;
    num skeletonR = skeleton.r;
    num skeletonG = skeleton.g;
    num skeletonB = skeleton.b;
    num skeletonA = skeleton.a;

    renderContextWebGL.activateRenderProgram(renderProgram);

    for (var slot in skeleton.drawOrder) {

      Int16List ixList = null;
      Float32List vxList = null;
      RenderTexture renderTexture = null;
      Attachment attachment = slot.attachment;

      num attachmentR = 0.0;
      num attachmentG = 0.0;
      num attachmentB = 0.0;
      num attachmentA = 0.0;

      if (attachment is RegionAttachment) {

        ixList = attachment.triangles;
        vxList = attachment.getWorldVertices(skeletonX, skeletonY, slot);
        attachmentR = attachment.r;
        attachmentG = attachment.g;
        attachmentB = attachment.b;
        attachmentA = attachment.a;
        renderTexture = attachment.bitmapData.renderTexture;

      } else if (attachment is MeshAttachment) {

        ixList = attachment.triangles;
        vxList = attachment.getWorldVertices(skeletonX, skeletonY, slot);
        attachmentR = attachment.r;
        attachmentG = attachment.g;
        attachmentB = attachment.b;
        attachmentA = attachment.a;
        renderTexture = attachment.bitmapData.renderTexture;

      } else if (attachment is SkinnedMeshAttachment) {

        ixList = attachment.triangles;
        vxList = attachment.getWorldVertices(skeletonX, skeletonY, slot);
        attachmentR = attachment.r;
        attachmentG = attachment.g;
        attachmentB = attachment.b;
        attachmentA = attachment.a;
        renderTexture = attachment.bitmapData.renderTexture;
      }

      if (renderTexture != null) {
        num r = attachmentR * skeletonR * slot.r;
        num g = attachmentG * skeletonG * slot.g;
        num b = attachmentB * skeletonB * slot.b;
        num a = attachmentA * skeletonA * slot.a;
        renderContextWebGL.activateRenderTexture(renderTexture);
        renderContextWebGL.activateBlendMode(slot.data.blendMode);
        renderProgram.renderTextureMesh(renderState, ixList, vxList, r, g, b, a);
      }
    }
  }

  //---------------------------------------------------------------------------

  void _renderCanvas(RenderState renderState) {

    RenderContext renderContext = renderState.renderContext;
    Matrix globalMatrix = renderState.globalMatrix.clone();
    BlendMode globalBlendMode = renderState.globalBlendMode;
    num globalAlpha = renderState.globalAlpha;
    Matrix tmpMatrix = new Matrix.fromIdentity();
    RenderState tmpRenderState = new RenderState(renderContext);

    num skeletonX = skeleton.x;
    num skeletonY = skeleton.y;
    num skeletonA = skeleton.a;

    for (var slot in skeleton.drawOrder) {

      Int16List ixList = null;
      Float32List vxList = null;
      Attachment attachment = slot.attachment;
      BlendMode blendMode = globalBlendMode;
      num alpha = 0.0;

      if (attachment is RegionAttachment) {

        var bd = attachment.bitmapData;
        blendMode = slot.data.blendMode;
        alpha = globalAlpha * skeletonA * attachment.a * slot.a;
        tmpMatrix.copyFrom(attachment.matrix);
        tmpMatrix.translate(skeletonX, skeletonY);
        tmpMatrix.concat(slot.bone.worldMatrix);
        tmpMatrix.concat(globalMatrix);
        tmpRenderState.reset(tmpMatrix, alpha, blendMode);
        tmpRenderState.renderTextureQuad(bd.renderTextureQuad);

      } else if (attachment is MeshAttachment) {

        var bd = attachment.bitmapData;
        blendMode = slot.data.blendMode;
        alpha = globalAlpha * skeletonA * attachment.a * slot.a;
        ixList = attachment.triangles;
        vxList = attachment.getWorldVertices(skeletonX, skeletonY, slot);
        tmpRenderState.reset(globalMatrix, alpha, blendMode);
        tmpRenderState.renderTextureMesh(bd.renderTexture, ixList, vxList);

      } else if (attachment is SkinnedMeshAttachment) {

        var bd = attachment.bitmapData;
        blendMode = slot.data.blendMode;
        alpha = globalAlpha * skeletonA * attachment.a * slot.a;
        ixList = attachment.triangles;
        vxList = attachment.getWorldVertices(skeletonX, skeletonY, slot);
        tmpRenderState.reset(globalMatrix, alpha, blendMode);
        tmpRenderState.renderTextureMesh(bd.renderTexture, ixList, vxList);
      }
    }
  }

}
