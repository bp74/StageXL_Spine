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
    List<num> uvList = new List<num>(8);
    List<num> xyList = new List<num>(8);

    renderProgram.configure(renderContextWebGL, matrix);

    //---------------------------------------------------

    for (var i = 0; i < drawOrder.length; i++) {

      Slot slot= drawOrder[i];
      Bone bone = slot.bone;
      Attachment attachment = slot.attachment;

      num attachmentR = 0.0;
      num attachmentG = 0.0;
      num attachmentB = 0.0;
      num attachmentA = 0.0;

      //---------------------------------------------------

      if (attachment is RegionAttachment) {

        RegionAttachment regionAttachment = attachment;
        AtlasRegion altasRegion = regionAttachment.rendererObject;

        regionAttachment.computeWorldVertices(skeletonX, skeletonY, bone, xyList);
        uvList = regionAttachment.uvs;
        attachmentR = regionAttachment.r;
        attachmentG = regionAttachment.g;
        attachmentB = regionAttachment.b;
        attachmentA = regionAttachment.a;
        renderTexture = altasRegion.page.rendererObject;

      } else if (attachment is MeshAttachment) {

        // TODO: attachment is MeshAttachment

      } else if (attachment is SkinnedMeshAttachment) {

        // TODO: attachment is SkinnedMeshAttachment

      }

      //---------------------------------------------------

      if (renderTexture != null) {

        num rr = attachmentR * skeletonR * slot.r;
        num gg = attachmentG * skeletonG * slot.g;
        num bb = attachmentB * skeletonB * slot.b;
        num aa = attachmentA * skeletonA * slot.a;

        renderContextWebGL.activateRenderTexture(renderTexture);
        renderContextWebGL.activateBlendMode(slot.data.additiveBlending ? BlendMode.ADD : blendMode);
        renderProgram.renderRegion(uvList, xyList, rr, gg, bb, aa);
      }
    }
  }

  //-----------------------------------------------------------------------------------------------

  void _renderCanvas(RenderState renderState) {
    // TODO: render with RenderContextCanvas
  }

  /*
  void advanceTime(num delta) {

    skeleton.update(delta * timeScale);

    // This is just a test implementation! Not optimized yet :)
    // Of course we will override the render method in the future.

    removeChildren();

    List<Slot> drawOrder = skeleton.drawOrder;

    for (int i = 0; i < drawOrder.length; i++) {

      Slot slot = drawOrder[i];
      RegionAttachment regionAttachment = slot.attachment as RegionAttachment;

      if (regionAttachment != null) {

        AtlasRegion region = regionAttachment.rendererObject as AtlasRegion;
        BitmapData bitmapData = region.page.rendererObject as BitmapData;
        RenderTextureQuad renderTextureQuad;

        if (region.rotate) {
          renderTextureQuad = new RenderTextureQuad(bitmapData.renderTexture, 3,
              region.offsetX, region.offsetY,
              region.x, region.y + region.width, region.width, region.height);
        } else {
          renderTextureQuad = new RenderTextureQuad(bitmapData.renderTexture, 0,
              region.offsetX, region.offsetY,
              region.x, region.y, region.width, region.height);
        }

        BitmapData regionBitmapData = new BitmapData.fromRenderTextureQuad(renderTextureQuad);
        Bitmap regionBitmap = new Bitmap(regionBitmapData);

        regionBitmap.rotation = -regionAttachment.rotation * math.PI / 180;
        regionBitmap.scaleX = regionAttachment.scaleX * regionAttachment.width / region.width;
        regionBitmap.scaleY = regionAttachment.scaleY * regionAttachment.height / region.height;

        regionBitmap.x = regionAttachment.x;
        regionBitmap.y = - regionAttachment.y;
        regionBitmap.pivotX = regionAttachment.width / 2;
        regionBitmap.pivotY = regionAttachment.height / 2;

        /*
        var colorTransform:ColorTransform = wrapper.transform.colorTransform;
        colorTransform.redMultiplier = skeleton.r * slot.r * regionAttachment.r;
        colorTransform.greenMultiplier = skeleton.g * slot.g * regionAttachment.g;
        colorTransform.blueMultiplier = skeleton.b * slot.b * regionAttachment.b;
        colorTransform.alphaMultiplier = skeleton.a * slot.a * regionAttachment.a;
        */

        int flipX = skeleton.flipX ? -1 : 1;
        int flipY = skeleton.flipY ? -1 : 1;
        Bone bone = slot.bone;

        Sprite wrapper = new Sprite();
        wrapper.addChild(regionBitmap);
        wrapper.x = bone.worldX;
        wrapper.y = bone.worldY;
        wrapper.rotation = -bone.worldRotation * flipX * flipY * math.PI / 180.0;
        wrapper.scaleX = bone.worldScaleX * flipX;
        wrapper.scaleY = bone.worldScaleY * flipY;
        wrapper.alpha = skeleton.a * slot.a * regionAttachment.a;
        wrapper.blendMode = slot.data.additiveBlending ? BlendMode.ADD : BlendMode.NORMAL;

        addChild(wrapper);
      }
    }

    return true;
  }
  */

}
