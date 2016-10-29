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

class MeshAttachment extends VertexAttachment implements _RenderAttachment {

  final String path;
  final BitmapData bitmapData;

  Float32List worldVertices;
  Float32List regionUVs;
  Int16List triangles;
  Int16List edges;

  double r = 1.0;
  double g = 1.0;
  double b = 1.0;
  double a = 1.0;

  int hullLength = 0;
  bool inheritDeform = false;
  double width = 0.0;
  double height = 0.0;

  Int16List _ixList;
  Float32List _vxList;
  MeshAttachment _parentMesh;

  MeshAttachment(String name, this.path, this.bitmapData) : super(name);

  //---------------------------------------------------------------------------

  MeshAttachment get parentMesh => _parentMesh;

  set parentMesh(MeshAttachment parentMesh) {
    _parentMesh = parentMesh;
    if (parentMesh != null) {
      bones = parentMesh.bones;
      vertices = parentMesh.vertices;
      worldVerticesLength = parentMesh.worldVerticesLength;
      regionUVs = parentMesh.regionUVs;
      triangles = parentMesh.triangles;
      hullLength = parentMesh.hullLength;
      edges = parentMesh.edges;
      width = parentMesh.width;
      height = parentMesh.height;
    }
  }

  bool applyFFD(Attachment sourceAttachment) {
    if (sourceAttachment == this) return true;
    if (sourceAttachment == _parentMesh && inheritDeform) return true;
    return false;
  }

  //---------------------------------------------------------------------------

  void updateUVs()  {

    var matrix = bitmapData.renderTextureQuad.samplerMatrix;
    var ma = matrix.a * bitmapData.width;
    var mb = matrix.b * bitmapData.width;
    var mc = matrix.c * bitmapData.height;
    var md = matrix.d * bitmapData.height;
    var mx = matrix.tx;
    var my = matrix.ty;

    _ixList = this.triangles;
    _vxList = new Float32List(regionUVs.length * 2);

    for (int i = 0, o = 0; i < regionUVs.length - 1; i += 2, o += 4) {
      var u = regionUVs[i + 0];
      var v = regionUVs[i + 1];
      _vxList[o + 2] = u * ma + v * mc + mx;
      _vxList[o + 3] = u * mb + v * md + my;
    }
  }

  //---------------------------------------------------------------------------

  Int16List get ixList => _ixList;

  Float32List getVertexList(double posX, double posY, Slot slot) {

    // TODO: make this more efficient!

    if (worldVertices == null || worldVertices.length < worldVerticesLength) {
      worldVertices = new Float32List(worldVerticesLength);
    }

    this.computeWorldVertices(slot, worldVertices);

    for (int i = 0, o = 0; i <= worldVertices.length - 2; i += 2, o += 4) {
      _vxList[o + 0] = posX + worldVertices[i + 0];
      _vxList[o + 1] = posY - worldVertices[i + 1];
    }

    return _vxList;
  }

}
