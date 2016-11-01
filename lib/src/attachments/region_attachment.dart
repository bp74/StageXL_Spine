/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;

class RegionAttachment extends Attachment implements _RenderAttachment {

  final String path;

  double x = 0.0;
  double y = 0.0;
  double width = 0.0;
  double height = 0.0;
  double scaleX = 1.0;
  double scaleY = 1.0;
  double rotation = 0.0;

  final Matrix transformationMatrix = new Matrix.fromIdentity();
  Float32List _vxListWithTransformation;

  @override BitmapData bitmapData;
  @override Float32List vxList;
  @override Int16List ixList;
  @override int hullLength = 0;
  @override double r = 1.0;
  @override double g = 1.0;
  @override double b = 1.0;
  @override double a = 1.0;

  RegionAttachment(String name, this.path, this.bitmapData) : super(name) {
    this.initRenderGeometry();
    this.update();
  }

  //---------------------------------------------------------------------------

  /// The update method will update the [transformationMatrix] based on the
  /// x, y, width, height, scaleX, scaleY and rotation fields. Therefore you
  /// have to call this method after you have changed one of those fields.

  void update() {

    num sw = scaleX * width;
    num sh = scaleY * height;
    num bw = bitmapData.width;
    num bh = bitmapData.height;
    num cosR = _cosDeg(rotation);
    num sinR = _sinDeg(rotation);

    num ma = cosR * sw / bw;
    num mb = sinR * sw / bw;
    num mc = sinR * sh / bh;
    num md = 0.0 - cosR * sh / bh;
    num mx = x - 0.5 * (sw * cosR + sh * sinR);
    num my = y - 0.5 * (sw * sinR - sh * cosR);
    transformationMatrix.setTo(ma, mc, mb, md, mx, my);

    for (int i = 0; i <= vxList.length - 4; i += 4) {
      var x = vxList[i + 0];
      var y = vxList[i + 1];
      _vxListWithTransformation[i + 0] = x * ma + y * mb + mx;
      _vxListWithTransformation[i + 1] = x * mc + y * md + my;
    }
  }

  //---------------------------------------------------------------------------

  @override
  void initRenderGeometry() {
    hullLength = bitmapData.renderTextureQuad.vxList.length >> 1;
    ixList = new Int16List.fromList(bitmapData.renderTextureQuad.ixList);
    vxList = new Float32List.fromList(bitmapData.renderTextureQuad.vxList);
    _vxListWithTransformation = new Float32List.fromList(vxList);
  }

  @override
  void updateRenderGeometry(Slot slot) {

    var vxData = _vxListWithTransformation;
    var vxList = this.vxList;
    var bone = slot.bone;

    var ba = bone.a;
    var bb = bone.b;
    var bc = bone.c;
    var bd = bone.d;
    var bx = bone.worldX;
    var by = bone.worldY;

    for (int i = 0; i <= vxList.length - 4; i += 4) {
      var x = vxData[i + 0];
      var y = vxData[i + 1];
      vxList[i + 0] = x * ba + y * bb + bx;
      vxList[i + 1] = x * bc + y * bd + by;
    }
  }
}
