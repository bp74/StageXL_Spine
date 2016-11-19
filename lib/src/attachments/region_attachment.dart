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

class RegionAttachment extends Attachment implements RenderableAttachment {

  final String path;

  double x = 0.0;
  double y = 0.0;
  double width = 0.0;
  double height = 0.0;
  double scaleX = 1.0;
  double scaleY = 1.0;
  double rotation = 0.0;

  final Matrix transformationMatrix = new Matrix.fromIdentity();
  Float32List vertices;

  @override BitmapData bitmapData;
  @override Float32List vxList;
  @override Int16List ixList;
  @override int hullLength = 0;
  @override int worldVerticesLength = 0;

  @override double r = 1.0;
  @override double g = 1.0;
  @override double b = 1.0;
  @override double a = 1.0;

  RegionAttachment(String name, this.path, this.bitmapData) : super(name) {
    this.initRenderGeometry();
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
    num mb = sinR * sh / bh;
    num mc = sinR * sw / bw;
    num md = 0.0 - cosR * sh / bh;
    num mx = x - 0.5 * (sw * cosR + sh * sinR);
    num my = y - 0.5 * (sw * sinR - sh * cosR);
    transformationMatrix.setTo(ma, mc, mb, md, mx, my);

    Float32List vxList = bitmapData.renderTextureQuad.vxList;

    for (int o = 0; o <= vertices.length - 2; o += 2) {
      double x = vxList[o * 2 + 0];
      double y = vxList[o * 2 + 1];
      vertices[o + 0] = x * ma + y * mb + mx;
      vertices[o + 1] = x * mc + y * md + my;
    }
  }

  //---------------------------------------------------------------------------

  @override
  void initRenderGeometry() {
    var renderTextureQuad = bitmapData.renderTextureQuad;
    this.ixList = new Int16List.fromList(renderTextureQuad.ixList);
    this.vxList = new Float32List.fromList(renderTextureQuad.vxList);
    this.worldVerticesLength = this.hullLength = vxList.length >> 1;
    this.vertices = new Float32List(worldVerticesLength);
    this.update();
  }

  @override
  void updateRenderGeometry(Slot slot) {
    computeWorldVertices2(slot, 0, worldVerticesLength, vxList, 0, 4);
  }

  @override
  void computeWorldVertices(Slot slot, Float32List worldVertices) {
    computeWorldVertices2(slot, 0, worldVerticesLength, worldVertices, 0, 2);
  }

  @override
  void computeWorldVertices2(
      Slot slot, int start, int count,
      Float32List worldVertices, int offset, int stride) {

    var ma = slot.bone.a;
    var mb = slot.bone.b;
    var mc = slot.bone.c;
    var md = slot.bone.d;
    var mx = slot.bone.worldX;
    var my = slot.bone.worldY;
    var length = count >> 1;

    for (int i = 0; i < length; i++, start += 2, offset += stride) {
      double x = vertices[start + 0];
      double y = vertices[start + 1];
      worldVertices[offset + 0] = x * ma + y * mb + mx;
      worldVertices[offset + 1] = x * mc + y * md + my;
    }
  }
}
