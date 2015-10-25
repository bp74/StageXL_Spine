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

class MeshAttachment extends Attachment implements _RenderAttachment {

  final String path;
  final BitmapData bitmapData;

  num width = 0.0, height = 0.0;
  num r = 1.0, g = 1.0, b = 1.0, a = 1.0;
  int hullLength = 0;
  int vertexLength = 0;

  Int16List edges = null;
  Int16List ixList = null;
  Float32List vxList = null;
  Float32List vertices = null;

  MeshAttachment(String name, this.path, this.bitmapData) : super(name);

  //---------------------------------------------------------------------------

  void update(Int16List triangles, Float32List vertices, Float32List uvs) {

    this.ixList = triangles;
    this.vxList = new Float32List(vertices.length * 2);
    this.vertices = vertices;
    this.vertexLength = vertices.length;

    var matrix = bitmapData.renderTextureQuad.samplerMatrix;
    var ma = matrix.a * bitmapData.width;
    var mb = matrix.b * bitmapData.width;
    var mc = matrix.c * bitmapData.height;
    var md = matrix.d * bitmapData.height;
    var mx = matrix.tx;
    var my = matrix.ty;

    for (int i = 0, o = 0; i < uvs.length - 1; i += 2, o+= 4) {
      var u = uvs[i + 0];
      var v = uvs[i + 1];
      this.vxList[o + 2] = u * ma + v * mc + mx;
      this.vxList[o + 3] = u * mb + v * md + my;
    }
  }

  //---------------------------------------------------------------------------

  Float32List getVertexList(num posX, num posY, Slot slot) {

    var matrix = slot.bone.worldMatrix;
    var vertices = this.vertices;
    var vxList = this.vxList;

    var ma = matrix.a;
    var mb = matrix.b;
    var mc = matrix.c;
    var md = matrix.d;
    var mx = matrix.tx + posX;
    var my = matrix.ty + posY;

    if (slot.attachmentVertices.length == vertices.length) {
      this.vertices = vertices = slot.attachmentVertices;
    }

    for (int i = 0, o = 0; i <= vertices.length - 2; i += 2, o += 4) {
      var x = vertices[i + 0];
      var y = vertices[i + 1];
      vxList[o + 0] = x * ma + y * mc + mx;
      vxList[o + 1] = x * mb + y * md + my;
    }

    return vxList;
  }
}
