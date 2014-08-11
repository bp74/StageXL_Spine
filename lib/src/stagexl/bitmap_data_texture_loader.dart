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

class BitmapDataTextureLoader implements TextureLoader {

  Map<String, BitmapData> _bitmapDatas = new Map<String, BitmapData>();
  BitmapData _singleBitmapData = null;

  /// The [bitmapDatas] parameter may be a BitmapData for an atlas that has
  /// only one page, or for a multi page atlas an object where the key is
  /// the image path and the value is the BitmapData.

  BitmapDataTextureLoader(dynamic bitmapDatas) {
    if (bitmapDatas is BitmapData) {
      _singleBitmapData = bitmapDatas;
    } else if (bitmapDatas is Map) {
      _bitmapDatas = bitmapDatas;
    } else {
      throw new ArgumentError("Invalid bitmaps parameter.");
    }
  }

  //-----------------------------------------------------------------------------------------------
  //-----------------------------------------------------------------------------------------------

  void loadPage(AtlasPage page, String path) {

    BitmapData bitmapData;

    if (_singleBitmapData != null) {
      bitmapData = _singleBitmapData;
    } else if (_bitmapDatas.containsKey(path)) {
      bitmapData = _bitmapDatas[path];
    } else {
      throw new ArgumentError("BitmapData not found with name: $path");
    }

    page.renderTexture = bitmapData.renderTexture;
  }

  //-----------------------------------------------------------------------------------------------

  void unloadPage(AtlasPage page) {
    //RenderTexture renderTexture = page.rendererObject;
    //renderTexture.dispose();
  }

  //-----------------------------------------------------------------------------------------------

  void loadRegion(AtlasRegion region) {

    var renderTexture = region.page.renderTexture;

    if (region.rotate) {
      region.renderTextureQuad = new RenderTextureQuad(renderTexture, 3,
          region.offsetX, region.offsetY,
          region.x, region.y + region.width, region.width, region.height);
    } else {
      region.renderTextureQuad = new RenderTextureQuad(renderTexture, 0,
          region.offsetX, region.offsetY,
          region.x, region.y, region.width, region.height);
    }
  }

}
