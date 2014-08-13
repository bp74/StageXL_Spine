part of stagexl_spine;

class SkeletonDisplayObject extends DisplayObject {

  final Skeleton skeleton;
  num timeScale = 1.0;

  SkeletonDisplayObject(SkeletonData skeletonData) : skeleton = new Skeleton(skeletonData) {
    skeleton.updateWorldTransform();
  }

  //-----------------------------------------------------------------------------------------------

  void render(RenderState renderState) {
    var renderContext = renderState.renderContext;
    if (renderContext is RenderContextWebGL) {
      _renderWebGL(renderState);
    } else {
      _renderCanvas(renderState);
    }
  }

  //-----------------------------------------------------------------------------------------------

  void _renderWebGL(RenderState renderState) {

    var renderProgram = _SpineRenderProgram.instance;
    var renderContext = renderState.renderContext;
    var matrix = renderState.globalMatrix;
    var blendMode = renderState.globalBlendMode;

    RenderContextWebGL renderContextWebGL = renderContext;
    RenderTexture renderTexture = null;

    num skeletonX = skeleton.x;
    num skeletonY = skeleton.y;
    num skeletonR = skeleton.r;
    num skeletonG = skeleton.g;
    num skeletonB = skeleton.b;
    num skeletonA = skeleton.a;

    List<Slot> drawOrder = skeleton.drawOrder;
    List<num> uvList = new List<num>();
    List<num> xyList = new List<num>();
    List<int> indexList = new List<int>();
    List<int> regionIndexList = new List<int>.from([0, 1, 2, 0, 2, 3]);

    renderProgram.configure(renderContextWebGL, matrix);
    xyList.length = 8;

    //---------------------------------------------------

    for (var i = 0; i < drawOrder.length; i++) {

      Slot slot = drawOrder[i];
      Bone bone = slot.bone;
      Attachment attachment = slot.attachment;

      num attachmentR = 0.0;
      num attachmentG = 0.0;
      num attachmentB = 0.0;
      num attachmentA = 0.0;
      int verticesLength = 0;

      //---------------------------------------------------

      if (attachment is RegionAttachment) {

        RegionAttachment regionAttachment = attachment;

        verticesLength = 8;
        regionAttachment.computeWorldVertices(skeletonX, skeletonY, bone, xyList);
        uvList = regionAttachment.uvs;
        indexList = regionIndexList;

        attachmentR = regionAttachment.r;
        attachmentG = regionAttachment.g;
        attachmentB = regionAttachment.b;
        attachmentA = regionAttachment.a;
        renderTexture = regionAttachment.atlasRegion.page.renderTexture;

      } else if (attachment is MeshAttachment) {

        MeshAttachment meshAttachment = attachment;

        verticesLength = meshAttachment.vertices.length;
        if (xyList.length < verticesLength) xyList.length = verticesLength;
        meshAttachment.computeWorldVertices(skeletonX, skeletonY, slot, xyList);
        uvList = meshAttachment.uvs;
        indexList = meshAttachment.triangles;

        attachmentR = meshAttachment.r;
        attachmentG = meshAttachment.g;
        attachmentB = meshAttachment.b;
        attachmentA = meshAttachment.a;
        renderTexture = meshAttachment.atlasRegion.page.renderTexture;

      } else if (attachment is SkinnedMeshAttachment) {

        SkinnedMeshAttachment skinnedMesh = attachment;

        verticesLength = skinnedMesh.uvs.length;
        if (xyList.length < verticesLength) xyList.length = verticesLength;
        skinnedMesh.computeWorldVertices(skeletonX, skeletonY, slot, xyList);
        uvList = skinnedMesh.uvs;
        indexList = skinnedMesh.triangles;

        attachmentR = skinnedMesh.r;
        attachmentG = skinnedMesh.g;
        attachmentB = skinnedMesh.b;
        attachmentA = skinnedMesh.a;
        renderTexture = skinnedMesh.atlasRegion.page.renderTexture;
      }

      //---------------------------------------------------

      if (renderTexture != null) {

        num rr = attachmentR * skeletonR * slot.r;
        num gg = attachmentG * skeletonG * slot.g;
        num bb = attachmentB * skeletonB * slot.b;
        num aa = attachmentA * skeletonA * slot.a;

        renderContextWebGL.activateRenderTexture(renderTexture);
        renderContextWebGL.activateBlendMode(slot.data.additiveBlending ? BlendMode.ADD : blendMode);
        renderProgram.renderMesh(indexList, xyList, uvList, rr, gg, bb, aa);
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
        AtlasRegion region = regionAttachment.atlasRegion;
        RenderTextureQuad renderTextureQuad = region.renderTextureQuad;
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
