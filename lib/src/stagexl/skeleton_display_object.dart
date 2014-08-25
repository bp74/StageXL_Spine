part of stagexl_spine;

class SkeletonDisplayObject extends DisplayObject {

  final Skeleton skeleton;
  num timeScale = 1.0;

  SkeletonDisplayObject(SkeletonData skeletonData) : skeleton = new Skeleton(skeletonData) {
    skeleton.updateWorldTransform();
  }

  //-----------------------------------------------------------------------------------------------

  Rectangle<num> getBoundsTransformed(Matrix matrix, [Rectangle<num> returnRectangle]) {
    // Currently bounds are not supported.
    // We sould offer add an opt-in flag.
    return super.getBoundsTransformed(matrix, returnRectangle);
  }

  DisplayObject hitTestInput(num localX, num localY) {
    // Currently hitTests are not supported.
    // We sould offer add an opt-in flag.
    return null;
  }

  void render(RenderState renderState) {
    var renderContext = renderState.renderContext;
    if (renderContext is RenderContextWebGL) {
      _renderWebGL(renderState);
    } else {
      _renderCanvas(renderState);
    }
  }

  //-----------------------------------------------------------------------------------------------

  static Float32List _xyList = new Float32List(256);
  static Int16List _indexList = new Int16List.fromList([0, 1, 2, 0, 2, 3]);

  void _renderWebGL(RenderState renderState) {

    var renderContext = renderState.renderContext;
    var globalMatrix = renderState.globalMatrix;
    var blendMode = renderState.globalBlendMode;

    RenderContextWebGL renderContextWebGL = renderContext;
    RenderProgramMesh renderProgramMesh = renderContextWebGL.renderProgramMesh;

    num skeletonX = skeleton.x;
    num skeletonY = skeleton.y;
    num skeletonR = skeleton.r;
    num skeletonG = skeleton.g;
    num skeletonB = skeleton.b;
    num skeletonA = skeleton.a;

    renderContextWebGL.flush();
    renderContextWebGL.activateRenderProgram(renderProgramMesh);
    renderProgramMesh.globalMatrix = globalMatrix;

    Float32List xyList = _xyList;
    Float32List uvList = new Float32List(0);
    Int16List indexList = new Int16List(0);

    //---------------------------------------------------

    List<Slot> drawOrder = skeleton.drawOrder;

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

      //---------------------------------------------------

      if (attachment is RegionAttachment) {

        RegionAttachment regionAttachment = attachment;

        regionAttachment.computeWorldVertices(skeletonX, skeletonY, bone, xyList);
        uvList = regionAttachment.uvs;
        indexList = _indexList;
        vertexCount = 4;
        indexCount = 6;

        attachmentR = regionAttachment.r;
        attachmentG = regionAttachment.g;
        attachmentB = regionAttachment.b;
        attachmentA = regionAttachment.a;
        renderTexture = regionAttachment.bitmapData.renderTexture;

      } else if (attachment is MeshAttachment) {

        MeshAttachment meshAttachment = attachment;

        uvList = meshAttachment.uvs;
        indexList = meshAttachment.triangles;
        vertexCount = uvList.length >> 1;
        indexCount = indexList.length;

        if (xyList.length < uvList.length) {
          xyList = _xyList = new Float32List(uvList.length);
        }

        meshAttachment.computeWorldVertices(skeletonX, skeletonY, slot, xyList);

        attachmentR = meshAttachment.r;
        attachmentG = meshAttachment.g;
        attachmentB = meshAttachment.b;
        attachmentA = meshAttachment.a;
        renderTexture = meshAttachment.bitmapData.renderTexture;

      } else if (attachment is SkinnedMeshAttachment) {

        SkinnedMeshAttachment skinnedMesh = attachment;

        uvList = skinnedMesh.uvs;
        indexList = skinnedMesh.triangles;
        vertexCount = uvList.length >> 1;
        indexCount = indexList.length;

        if (xyList.length < uvList.length) {
          xyList = _xyList = new Float32List(uvList.length);
        }

        skinnedMesh.computeWorldVertices(skeletonX, skeletonY, slot, xyList);

        attachmentR = skinnedMesh.r;
        attachmentG = skinnedMesh.g;
        attachmentB = skinnedMesh.b;
        attachmentA = skinnedMesh.a;
        renderTexture = skinnedMesh.bitmapData.renderTexture;
      }

      //---------------------------------------------------

      if (renderTexture != null) {

        num rr = attachmentR * skeletonR * slot.r;
        num gg = attachmentG * skeletonG * slot.g;
        num bb = attachmentB * skeletonB * slot.b;
        num aa = attachmentA * skeletonA * slot.a;

        renderContextWebGL.activateRenderTexture(renderTexture);
        renderContextWebGL.activateBlendMode(slot.data.additiveBlending ? BlendMode.ADD : blendMode);
        renderProgramMesh.renderMesh(indexCount, indexList, vertexCount, xyList, uvList, rr, gg, bb, aa);
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
    List<Slot> drawOrder = skeleton.drawOrder;

    for (int i = 0; i < drawOrder.length; i++) {

      Slot slot = drawOrder[i];
      Bone bone = slot.bone;
      Attachment attachment = slot.attachment;

      if (attachment is RegionAttachment) {

        RegionAttachment regionAttachment = attachment;
        RenderTextureQuad renderTextureQuad = regionAttachment.bitmapData.renderTextureQuad;
        BlendMode blendMode = slot.data.additiveBlending ? BlendMode.ADD : globalBlendMode;
        num alpha = globalAlpha * skeleton.a * regionAttachment.a * slot.a;

        tmpMatrix.copyFromAndConcat(regionAttachment.matrix, bone.worldMatrix);
        tmpMatrix.concat(globalMatrix);
        tmpRenderState.reset(tmpMatrix, alpha, blendMode);
        tmpRenderState.renderQuad(renderTextureQuad);
      }
    }
  }

}
