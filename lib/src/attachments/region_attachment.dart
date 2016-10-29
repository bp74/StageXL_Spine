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
  final BitmapData bitmapData;

  double rotation = 0.0;
  double x = 0.0, y = 0.0;
  double scaleX = 1.0, scaleY = 1.0;
  double width = 0.0, height = 0.0;
  double r = 1.0, g = 1.0, b = 1.0, a = 1.0;
  Matrix matrix = new Matrix.fromIdentity();

  Int16List ixList = null;
  Float32List vxList = null;
  Float32List vertices = null;

  RegionAttachment(String name, this.path, this.bitmapData) : super(name);

  //---------------------------------------------------------------------------

  void update() {

    var ixData = bitmapData.renderTextureQuad.ixList;
    var vxData = bitmapData.renderTextureQuad.vxList;

    this.ixList = new Int16List.fromList(ixData);
    this.vxList = new Float32List.fromList(vxData);
    this.vertices = new Float32List(vxData.length >> 1);

    this.matrix.identity();
    this.matrix.scale(width / bitmapData.width, height / bitmapData.height);
    this.matrix.translate(0.0 - width / 2, 0.0 - height / 2);
    this.matrix.scale(scaleX, scaleY);
    this.matrix.scale(1.0, -1.0);
    this.matrix.rotate(rotation * math.PI / 180.0);
    this.matrix.translate(x, y);

    var ma = matrix.a;
    var mb = matrix.b;
    var mc = matrix.c;
    var md = matrix.d;
    var mx = matrix.tx;
    var my = matrix.ty;

    for (int i = 0, o = 0; i <= vxData.length - 4; i += 4, o += 2) {
      var x = vxData[i + 0];
      var y = vxData[i + 1];
      this.vertices[o + 0] = x * ma + y * mc + mx;
      this.vertices[o + 1] = x * mb + y * md + my;
    }
  }

  //---------------------------------------------------------------------------

  Float32List getVertexList(double posX, double posY, Slot slot) {

    var vertices = this.vertices;
    var vxList = this.vxList;
    var bone = slot.bone;

    var ba = bone.a;
    var bb = bone.b;
    var bc = bone.c;
    var bd = bone.d;
    var bx = bone.worldX + posX;
    var by = bone.worldY + posY;

    for (int i = 0, o = 0; i <= vertices.length - 2; i += 2, o += 4) {
      var x = vertices[i + 0];
      var y = vertices[i + 1];
      vxList[o + 0] = 0.0 + x * ba + y * bb + bx;
      vxList[o + 1] = 0.0 - x * bc - y * bd - by;
    }

    return vxList;
  }

}
