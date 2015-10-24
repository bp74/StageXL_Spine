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

class RegionAttachment extends Attachment {

  final String path;
  final BitmapData bitmapData;

  num rotation = 0.0;
  num x = 0.0, y = 0.0;
  num scaleX = 1.0, scaleY = 1.0;
  num width = 0.0, height = 0.0;
  num r = 1.0, g = 1.0, b = 1.0, a = 1.0;
  Matrix matrix = new Matrix.fromIdentity();

  Int16List triangles = null;
  Float32List vertices = null;
  Float32List uvs = null;

  RegionAttachment(String name, this.path, this.bitmapData) : super(name);

  //---------------------------------------------------------------------------

  void update() {

    matrix.identity();
    matrix.scale(width / bitmapData.width, height / bitmapData.height);
    matrix.translate(0.0 - width / 2, 0.0 - height / 2);
    matrix.scale(scaleX, scaleY);
    matrix.scale(1.0, -1.0);
    matrix.rotate(rotation * math.PI / 180.0);
    matrix.translate(x, y);

    var ixData = bitmapData.renderTextureQuad.ixList;
    var vxData = bitmapData.renderTextureQuad.vxList;

    var ma = matrix.a;
    var mb = matrix.b;
    var mc = matrix.c;
    var md = matrix.d;
    var mx = matrix.tx;
    var my = matrix.ty;

    this.triangles = new Int16List(ixData.length);
    this.vertices = new Float32List(vxData.length >> 1);
    this.uvs = new Float32List(vxData.length >> 1);

    for (int i = 0; i < ixData.length; i++) {
      this.triangles[i] = ixData[i];
    }

    for (int i = 0; i <= vxData.length - 4; i += 4) {
      var x = vxData[i + 0];
      var y = vxData[i + 1];
      var u = vxData[i + 2];
      var v = vxData[i + 3];
      this.vertices[(i >> 1) + 0] = x * ma + y * mc + mx;
      this.vertices[(i >> 1) + 1] = x * mb + y * md + my;
      this.uvs[(i >> 1) + 0] = u;
      this.uvs[(i >> 1) + 1] = v;
    }
  }

  //---------------------------------------------------------------------------

  Float32List getWorldVertices(num posX, num posY, Slot slot) {

    var matrix = slot.bone.worldMatrix;
    var result = _tmpFloat32List;

    var ma = matrix.a;
    var mb = matrix.b;
    var mc = matrix.c;
    var md = matrix.d;
    var mx = matrix.tx + posX;
    var my = matrix.ty + posY;

    for (int i = 0; i < this.vertices.length - 1; i += 2) {
      var x = vertices[i + 0];
      var y = vertices[i + 1];
      var u = uvs[i + 0];
      var v = uvs[i + 1];
      result[(i << 1) + 0] = x * ma + y * mc + mx;
      result[(i << 1) + 1] = x * mb + y * md + my;
      result[(i << 1) + 2] = u;
      result[(i << 1) + 3] = v;
    }

    return result;
  }

}
