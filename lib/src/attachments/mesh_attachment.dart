/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 *
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

part of stagexl_spine;

class MeshAttachment extends FfdAttachment implements _RenderAttachment {

  final String path;
  final BitmapData bitmapData;

  num width = 0.0, height = 0.0;
  num r = 1.0, g = 1.0, b = 1.0, a = 1.0;
  int hullLength = 0;
  int vertexLength = 0;

  bool inheritFFD = false;
  MeshAttachment _parentMesh = null;

  Int16List edges = null;
  Int16List ixList = null;
  Float32List vxList = null;
  Float32List vertices = null;
  Float32List uvs = null;

  MeshAttachment(String name, this.path, this.bitmapData) : super(name);

  //---------------------------------------------------------------------------

  MeshAttachment get parentMesh => _parentMesh;

  set parentMesh(MeshAttachment parentMesh) {
    _parentMesh = parentMesh;
    if (parentMesh != null) {
      hullLength = parentMesh.hullLength;
      edges = parentMesh.edges;
      width = parentMesh.width;
      height = parentMesh.height;
      update(parentMesh.ixList, parentMesh.vertices, parentMesh.uvs);
    }
  }

  bool applyFFD(Attachment sourceAttachment) {
    if (sourceAttachment == this) return true;
    if (sourceAttachment == _parentMesh && inheritFFD) return true;
    return false;
  }

  //---------------------------------------------------------------------------

  void update(Int16List triangles, Float32List vertices, Float32List uvs) {

    this.uvs = uvs;
    this.vertices = vertices;
    this.vertexLength = vertices.length;

    this.ixList = triangles;
    this.vxList = new Float32List(vertices.length * 2);

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

    var vertices = this.vertices;
    var vxList = this.vxList;
    var bone = slot.bone;

    var ba = bone.a;
    var bb = bone.b;
    var bc = bone.c;
    var bd = bone.d;
    var bx = bone.worldX + posX;
    var by = bone.worldY + posY;

    if (slot.attachmentVertices.length == vertices.length) {
      vertices = slot.attachmentVertices;
    }

    for (int i = 0, o = 0; i <= vertices.length - 2; i += 2, o += 4) {
      var x = vertices[i + 0];
      var y = vertices[i + 1];
      vxList[o + 0] = 0.0 + x * ba + y * bb + bx;
      vxList[o + 1] = 0.0 - x * bc - y * bd - by;
    }

    return vxList;
  }
}
