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

class MeshAttachment extends Attachment {

  final BitmapData bitmapData;

  String path = null;
  Float32List vertices = null;
  Float32List uvs = null;
  Float32List regionUVs = null;
  Int16List triangles = null;
  Int16List edges = null;
  int hullLength = 0;
  num width = 0.0;
  num height = 0.0;
  num r = 1.0;
  num g = 1.0;
  num b = 1.0;
  num a = 1.0;


  MeshAttachment(String name, this.bitmapData) : super(name);

  void updateUVs() {

    if (uvs == null || uvs.length != regionUVs.length) {
      uvs = new Float32List(regionUVs.length);
    }

    var renderTextureQuad = bitmapData.renderTextureQuad;
    var uvList = renderTextureQuad.uvList;
    var u1 = uvList[0];
    var v1 = uvList[1];
    var u2 = uvList[4];
    var v2 = uvList[5];

    if (renderTextureQuad.rotation == 0 || renderTextureQuad.rotation == 2) {
      for (int i = 0; i < regionUVs.length - 1; i += 2) {
        uvs[i + 0] = u1 + regionUVs[i + 0] * (u2 - u1);
        uvs[i + 1] = v1 + regionUVs[i + 1] * (v2 - v1);
      }
    } else {
      for (int i = 0; i < regionUVs.length - 1; i += 2) {
        uvs[i + 0] = u1 + regionUVs[i + 1] * (u2 - u1);
        uvs[i + 1] = v1 + regionUVs[i + 0] * (v2 - v1);
      }
    }
  }

  void computeWorldVertices(num x, num y, Slot slot, Float32List worldVertices) {

    Matrix matrix = slot.bone.worldMatrix;

    num a  = matrix.a;
    num b  = matrix.b;
    num c  = matrix.c;
    num d  = matrix.d;
    num tx = matrix.tx + x;
    num ty = matrix.ty + y;

    if (slot.attachmentVertices.length == this.vertices.length) {
      this.vertices = slot.attachmentVertices;
    }

    for (int i = 0; i < this.vertices.length - 1; i += 2) {
      num vx = this.vertices[i + 0];
      num vy = this.vertices[i + 1];
      worldVertices[i + 0] = vx * a + vy * c + tx;
      worldVertices[i + 1] = vx * b + vy * d + ty;
    }
  }
}
