part of stagexl_spine;

class SkeletonDisplayObject extends DisplayObject {

  final Skeleton skeleton;
  num timeScale = 1.0;

  SkeletonDisplayObject(SkeletonData skeletonData) : skeleton = new Skeleton(skeletonData) {
    skeleton.updateWorldTransform();
  }

  //-----------------------------------------------------------------------------------------------

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

  //-----------------------------------------------------------------------------------------------

  static Float32List _xyList = new Float32List(4096);
  static Int16List _indexList = new Int16List.fromList([0, 1, 2, 0, 2, 3]);

  void _renderWebGL(RenderState renderState) {

    RenderContext renderContext = renderState.renderContext;
    RenderContextWebGL renderContextWebGL = renderContext;
    RenderProgramMesh renderProgramMesh = renderContextWebGL.renderProgramMesh;
    BlendMode globalBlendMode = renderState.globalBlendMode;

    Float32List xyList = _xyList;
    Float32List uvList = new Float32List(0);
    Int16List indexList = new Int16List(0);
    List<Slot> drawOrder = skeleton.drawOrder;

    num skeletonX = skeleton.x;
    num skeletonY = skeleton.y;
    num skeletonR = skeleton.r;
    num skeletonG = skeleton.g;
    num skeletonB = skeleton.b;
    num skeletonA = skeleton.a;

    renderContextWebGL.activateRenderProgram(renderProgramMesh);

    for (var i = 0; i < drawOrder.length; i++) {

      Slot slot = drawOrder[i];
      Bone bone = slot.bone;
      Attachment attachment = slot.attachment;
      RenderTexture renderTexture = null;
      int vertexCount = 0;
      int indexCount = 0;

      num attachmentR = 0.0;
      num attachmentG = 0.0;
      num attachmentB = 0.0;
      num attachmentA = 0.0;

      if (attachment is RegionAttachment) {

        uvList = attachment.uvs;
        indexList = _indexList;
        vertexCount = 4;
        indexCount = 6;

        attachment.computeWorldVertices(skeletonX, skeletonY, bone, xyList);

        attachmentR = attachment.r;
        attachmentG = attachment.g;
        attachmentB = attachment.b;
        attachmentA = attachment.a;
        renderTexture = attachment.bitmapData.renderTexture;

      } else if (attachment is MeshAttachment) {

        uvList = attachment.uvs;
        indexList = attachment.triangles;
        vertexCount = uvList.length >> 1;
        indexCount = indexList.length;

        attachment.computeWorldVertices(skeletonX, skeletonY, slot, xyList);

        attachmentR = attachment.r;
        attachmentG = attachment.g;
        attachmentB = attachment.b;
        attachmentA = attachment.a;
        renderTexture = attachment.bitmapData.renderTexture;

      } else if (attachment is SkinnedMeshAttachment) {

        uvList = attachment.uvs;
        indexList = attachment.triangles;
        vertexCount = uvList.length >> 1;
        indexCount = indexList.length;

        attachment.computeWorldVertices(skeletonX, skeletonY, slot, xyList);

        attachmentR = attachment.r;
        attachmentG = attachment.g;
        attachmentB = attachment.b;
        attachmentA = attachment.a;
        renderTexture = attachment.bitmapData.renderTexture;
      }

      if (renderTexture != null) {

        num rr = attachmentR * skeletonR * slot.r;
        num gg = attachmentG * skeletonG * slot.g;
        num bb = attachmentB * skeletonB * slot.b;
        num aa = attachmentA * skeletonA * slot.a;

        BlendMode blendMode = slot.data.additiveBlending ? BlendMode.ADD : globalBlendMode;

        renderContextWebGL.activateRenderTexture(renderTexture);
        renderContextWebGL.activateBlendMode(blendMode);

        renderProgramMesh.renderMesh(
            renderState,
            indexCount, indexList,
            vertexCount, xyList, uvList,
            rr, gg, bb, aa);
      }
    }
  }

  //-----------------------------------------------------------------------------------------------

  void _renderCanvas(RenderState renderState) {

    RenderContext renderContext = renderState.renderContext;
    Matrix globalMatrix = renderState.globalMatrix.clone();
    BlendMode globalBlendMode = renderState.globalBlendMode;
    num globalAlpha = renderState.globalAlpha;
    Matrix tmpMatrix = new Matrix.fromIdentity();
    RenderState tmpRenderState = new RenderState(renderContext);

    Float32List xyList = _xyList;
    Float32List uvList = new Float32List(0);
    Int16List indexList = new Int16List(0);
    List<Slot> drawOrder = skeleton.drawOrder;

    num skeletonX = skeleton.x;
    num skeletonY = skeleton.y;
    num skeletonA = skeleton.a;

    for (var i = 0; i < drawOrder.length; i++) {

      Slot slot = drawOrder[i];
      Bone bone = slot.bone;
      Attachment attachment = slot.attachment;
      BlendMode blendMode = globalBlendMode;
      int vertexCount = 0;
      int indexCount = 0;
      num alpha = 0.0;

      if (attachment is RegionAttachment) {

        blendMode = slot.data.additiveBlending ? BlendMode.ADD : globalBlendMode;
        alpha = globalAlpha * skeletonA * attachment.a * slot.a;

        tmpMatrix.copyFrom(attachment.matrix);
        tmpMatrix.translate(skeletonX, skeletonY);
        tmpMatrix.concat(bone.worldMatrix);
        tmpMatrix.concat(globalMatrix);

        tmpRenderState.reset(tmpMatrix, alpha, blendMode);
        tmpRenderState.renderQuad(attachment.bitmapData.renderTextureQuad);

      } else if (attachment is MeshAttachment) {

        blendMode = slot.data.additiveBlending ? BlendMode.ADD : globalBlendMode;
        alpha = globalAlpha * skeletonA * attachment.a * slot.a;

        uvList = attachment.uvs;
        indexList = attachment.triangles;
        vertexCount = uvList.length >> 1;
        indexCount = indexList.length;

        attachment.computeWorldVertices(skeletonX, skeletonY, slot, xyList);

        tmpRenderState.reset(globalMatrix, alpha, blendMode);
        renderContext.renderMesh(
            tmpRenderState, attachment.bitmapData.renderTexture,
            indexCount, indexList,
            vertexCount, xyList, uvList);

      } else if (attachment is SkinnedMeshAttachment) {

        blendMode = slot.data.additiveBlending ? BlendMode.ADD : globalBlendMode;
        alpha = globalAlpha * skeletonA * attachment.a * slot.a;

        uvList = attachment.uvs;
        indexList = attachment.triangles;
        vertexCount = uvList.length >> 1;
        indexCount = indexList.length;

        attachment.computeWorldVertices(skeletonX, skeletonY, slot, xyList);

        tmpRenderState.reset(globalMatrix, alpha, blendMode);
        renderContext.renderMesh(
            tmpRenderState, attachment.bitmapData.renderTexture,
            indexCount, indexList,
            vertexCount, xyList, uvList);
      }
    }
  }

}
