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

        num raRotation = regionAttachment.rotation * math.PI / 180;
        num raScaleX = regionAttachment.scaleX * regionAttachment.width / region.width;
        num raScaleY = regionAttachment.scaleY * regionAttachment.height / region.height;
        num raPivotX = regionAttachment.width / 2;
        num raPivotY = regionAttachment.height / 2;
        num raCos = math.cos(-raRotation);
        num raSin = math.sin(-raRotation);

        num a1 =   raScaleX * raCos;
        num b1 = - raScaleX * raSin;
        num c1 = - raScaleY * raSin;
        num d1 = - raScaleY * raCos;
        num tx1 =  regionAttachment.x - raPivotX * a1 - raPivotY * c1;
        num ty1 =  regionAttachment.y - raPivotX * b1 - raPivotY * d1;

        num a2 =  bone.m00;
        num b2 =  bone.m10;
        num c2 =  bone.m01;
        num d2 =  bone.m11;
        num tx2 = bone.worldX;
        num ty2 = bone.worldY;

        num a3 = a1 * a2 + b1 * c2;
        num b3 = a1 * b2 + b1 * d2;
        num c3 = c1 * a2 + d1 * c2;
        num d3 = c1 * b2 + d1 * d2;
        num tx3 = tx2 + tx1 * a2 + ty1 * c2;
        num ty3 = ty2 + tx1 * b2 + ty1 * d2;

        num alpha = globalAlpha * skeleton.a * regionAttachment.a * slot.a;
        BlendMode blendMode = slot.data.additiveBlending ? BlendMode.ADD : globalBlendMode;

        tmpMatrix.setTo(a3, b3, c3, d3, tx3, ty3);
        tmpMatrix.concat(globalMatrix);
        tmpRenderState.reset(tmpMatrix, alpha, blendMode);
        tmpRenderState.renderQuad(renderTextureQuad);
      }
    }
  }

}
